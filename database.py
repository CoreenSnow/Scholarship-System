import os
import psycopg2

def get_connection():
    DATABASE_URL = os.getenv('DATABASE_URL')
    if not DATABASE_URL:
        raise Exception('Please set DATABASE_URL env var')
    return psycopg2.connect(DATABASE_URL)
