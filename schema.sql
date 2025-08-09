CREATE TABLE IF NOT EXISTS users (
  user_id SERIAL PRIMARY KEY,
  name VARCHAR(200),
  password VARCHAR(20),
  wallet_address VARCHAR(42) UNIQUE,
  email VARCHAR(200),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS applications (
  app_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(user_id),
  student_name VARCHAR(200),
  university_college VARCHAR(200),
  program_of_study VARCHAR(200),
  expected_graduation_date DATE,
  academic_achievements VARCHAR(400),
  wallet_address VARCHAR(42) NOT NULL,
  status VARCHAR(20) DEFAULT 'pending',
  contract_app_id INTEGER,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  approved_at TIMESTAMPTZ NULL
);

CREATE TABLE IF NOT EXISTS donations (
  donation_id SERIAL PRIMARY KEY,
  name VARCHAR(200),
  wallet_address VARCHAR(42),
  amount_wei NUMERIC(38,0),
  amount_eth NUMERIC(36,18),
  tx_hash VARCHAR(100),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS admin_users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE,
  password TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS admin_actions (
  action_id SERIAL PRIMARY KEY,
  -- wallet_address VARCHAR(42),
  action_type VARCHAR(50),
  details JSONB,
  tx_hash VARCHAR(100),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS uploaded_document (
  document_id SERIAL PRIMARY KEY,
  app_id INTEGER REFERENCES applications(app_id),
  file_data BYTEA,
  uploaded_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
