import os
import json
from decimal import Decimal
from functools import wraps
import subprocess
from eth_account.messages import encode_defunct

from flask import (
    Flask, render_template, request, redirect, url_for, jsonify, session
)
from flask_bcrypt import Bcrypt
from flask_cors import CORS
from dotenv import load_dotenv
from web3 import Web3

from db import get_connection

load_dotenv()

app = Flask(__name__, static_folder='static', template_folder='templates')
CORS(app)

app.secret_key = os.getenv('SECRET_KEY', 'dev_secret_key')
bcrypt = Bcrypt(app)

RPC = os.getenv('RPC_URL', 'https://sapphire.oasis.io')
w3 = Web3(Web3.HTTPProvider(RPC))

CONTRACT_JSON_PATH = os.path.join(os.path.dirname(__file__), 'static', 'ScholarshipPool.json')
contract = None
CONTRACT_ADDRESS = os.getenv('CONTRACT_ADDRESS')

if CONTRACT_ADDRESS and os.path.exists(CONTRACT_JSON_PATH):
    with open(CONTRACT_JSON_PATH) as f:
        cj = json.load(f)
        abi = cj.get('abi', [])
        contract = w3.eth.contract(address=w3.to_checksum_address(CONTRACT_ADDRESS), abi=abi)

@app.route('/wallet_login', methods=['POST'])
def wallet_login():
    data = request.json
    wallet = data.get('wallet_address')
    signature = data.get('signature')
    message = data.get('message')  # The original message (nonce) that was signed

    if not wallet or not signature or not message:
        return jsonify({'error': 'Missing data'}), 400

    message_encoded = encode_defunct(text=message)
    recovered_address = w3.eth.account.recover_message(message_encoded, signature=signature)

    if recovered_address.lower() != wallet.lower():
        return jsonify({'error': 'Signature verification failed'}), 401

    # Connect DB
    conn = get_connection()
    cur = conn.cursor()

    # Check if wallet exists
    cur.execute("SELECT id, student_name FROM users WHERE wallet_address = %s", (wallet,))
    user = cur.fetchone()

    if user is None:
        # If user not found, create a new one with default name or empty
        cur.execute("INSERT INTO users (wallet_address, student_name) VALUES (%s, %s) RETURNING id, student_name", (wallet, ''))
        user = cur.fetchone()
        conn.commit()

    user_id, student_name = user

    cur.close()
    conn.close()

    # Save wallet and name in session for logged in user
    session['student_wallet'] = wallet
    session['student_name'] = student_name
    session['user_id'] = user_id

    return jsonify({'status': 'ok', 'user_id': user_id, 'student_name': student_name})

def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if 'admin' not in session:
            return redirect(url_for('admin_login'))
        return f(*args, **kwargs)
    return decorated_function

def is_valid_eth_address(address):
    return w3.isAddress(address)

def generate_sapphire_proof(input_data: dict) -> dict:
    """
    Call external Rust Sapphire proof generator binary.

    Returns dict with 'proof' and 'publicInputs'.
    Raises Exception if generation fails.
    """
    input_json = json.dumps(input_data)
    process = subprocess.run(
        ['./target/release/sapphire_proof_gen'],  # Adjust path to your Rust binary
        input=input_json.encode(),
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE
    )
    if process.returncode != 0:
        raise Exception(f"Proof generation failed: {process.stderr.decode()}")

    proof_output = json.loads(process.stdout.decode())
    return proof_output

def send_apply_with_proof_transaction(proof: str, public_inputs: list, from_wallet: str) -> str:
    # Build the contract function call transaction
    txn = contract.functions.applyWithProof(proof, public_inputs).buildTransaction({
        'from': from_wallet,
        'nonce': w3.eth.get_transaction_count(from_wallet),
        'gas': 3000000,  # estimate or set appropriately
        'gasPrice': w3.to_wei('20', 'gwei')
    })

    # Sign the transaction with the private key
    signed_txn = w3.eth.account.sign_transaction(txn, private_key=private_key)

    # Send the signed transaction
    tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)

    # Wait for transaction receipt (optional)
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash)

    # Return transaction hash as hex string
    return tx_hash.hex()

@app.route("/")
def index():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT id, student_name, student_wallet, amount_eth, status, created_at 
        FROM applications ORDER BY id DESC
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('applications.html', applications=rows)

@app.route('/apply', methods=['GET', 'POST'])
def apply():
    # Check if user logged in
    if 'student_wallet' not in session or 'student_name' not in session:
        return redirect(url_for('wallet_login_page'))  # Or wherever your login frontend is

    wallet = session['student_wallet']
    name = session['student_name']

    if request.method == 'POST':
        try:
            amount_eth = Decimal(request.form['amount_requested'])

            if amount_eth <= 0:
                return "Amount requested must be positive", 400
            if not is_valid_eth_address(wallet):
                return "Invalid Ethereum wallet address", 400

            amount_wei = int(w3.to_wei(amount_eth, 'ether'))
        except Exception as e:
            return f"Invalid input: {str(e)}", 400

        zk_input = {
            "student_name_hash": hash(name),
            "student_wallet": wallet,
            "amount_wei": str(amount_wei),
            # Add other zk circuit inputs as needed
        }

        try:
            proof_data = generate_sapphire_proof(zk_input)
        except Exception as e:
            return f"Proof generation error: {str(e)}", 500

        try:
            tx_hash = send_apply_with_proof_transaction(proof_data['proof'], proof_data['publicInputs'], wallet)
        except Exception as e:
            return f"Blockchain transaction failed: {str(e)}", 500

        conn = get_connection()
        cur = conn.cursor()
        cur.execute("""
            INSERT INTO applications (student_name, student_wallet, amount_wei, amount_eth, status, tx_hash) 
            VALUES (%s, %s, %s, %s, %s, %s) RETURNING id
        """, (name, wallet, str(amount_wei), str(amount_eth), 'pending', tx_hash))
        app_id = cur.fetchone()[0]
        conn.commit()
        cur.close()
        conn.close()

        return redirect(url_for('index'))

    # GET request
    return render_template('apply.html', student_name=name, student_wallet=wallet)

@app.route('/donate', methods=['GET'])
def donate_page():
    return render_template('donate.html')

@app.route('/admin/login', methods=['GET', 'POST'])
def admin_login():
    if request.method == 'POST':
        username = request.form['username'].strip()
        password = request.form['password']

        conn = get_connection()
        cur = conn.cursor()
        cur.execute("SELECT password_hash FROM admin_users WHERE username=%s", (username,))
        row = cur.fetchone()
        cur.close()
        conn.close()

        if row and bcrypt.check_password_hash(row[0], password):
            session['admin'] = username
            return redirect(url_for('admin_page'))
        return "Invalid credentials", 401
    return render_template('admin_login.html')

@app.route('/admin')
@login_required
def admin_page():
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        SELECT id, student_name, student_wallet, amount_eth, status FROM applications ORDER BY id DESC
    """)
    rows = cur.fetchall()
    cur.close()
    conn.close()
    return render_template('admin.html', applications=rows)

@app.route('/record_funding', methods=['POST'])
def record_funding():
    data = request.json
    tx_hash = data.get('tx_hash')
    donor_wallet = data.get('donor_wallet')
    donor_name = data.get('donor_name', donor_wallet)

    try:
        tx = w3.eth.get_transaction(tx_hash)
    except Exception as e:
        return jsonify({'error': 'Transaction not found', 'detail': str(e)}), 400

    amount_wei = tx['value']
    amount_eth = w3.from_wei(amount_wei, 'ether')

    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        INSERT INTO donations (donor_name, donor_wallet, amount_wei, amount_eth, tx_hash)
        VALUES (%s, %s, %s, %s, %s)
    """, (donor_name, donor_wallet, str(amount_wei), str(amount_eth), tx_hash))
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({'status': 'ok'})

@app.route('/record_approval', methods=['POST'])
@login_required
def record_approval():
    data = request.json
    app_id = int(data.get('app_id'))
    tx_hash = data.get('tx_hash')
    admin_wallet = data.get('admin_wallet')

    try:
        receipt = w3.eth.get_transaction_receipt(tx_hash)
    except Exception as e:
        return jsonify({'error': 'Transaction not found', 'detail': str(e)}), 400

    if receipt.get('status') != 1:
        return jsonify({'error': 'Transaction failed'}), 400

    conn = get_connection()
    cur = conn.cursor()
    cur.execute("""
        UPDATE applications SET status='approved', approved_at = CURRENT_TIMESTAMP WHERE id=%s
    """, (app_id,))
    cur.execute("""
        INSERT INTO admin_actions (admin_wallet, action_type, details, tx_hash)
        VALUES (%s, %s, %s, %s)
    """, (admin_wallet, 'approve', json.dumps({'app_id': app_id}), tx_hash))
    conn.commit()
    cur.close()
    conn.close()

    return jsonify({'status': 'ok'})

@app.route('/contract_balance', methods=['GET'])
def contract_balance():
    if not contract:
        return jsonify({'error': 'Contract not configured'}), 400

    bal = w3.eth.get_balance(contract.address)
    return jsonify({
        'balance_wei': str(bal),
        'balance_eth': str(w3.from_wei(bal, 'ether'))
    })

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
