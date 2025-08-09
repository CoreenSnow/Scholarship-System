CREATE USER scholarship_user WITH PASSWORD '0123';
GRANT ALL PRIVILEGES ON DATABASE "ScholarshipDB" TO scholarship_user;

CREATE TABLE IF NOT EXISTS users (
  user_id SERIAL PRIMARY KEY,
  name VARCHAR(200),
  password VARCHAR(20),
  wallet_address VARCHAR(42) UNIQUE,
  email VARCHAR(200),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO uploaded_document (user_id, name, wallet_address, email, password)
VALUES
(1, 'Jamal', '0x4f9c8B72FAbF95E3a7d6B18E4d1b9c8E2F1dA7c3', 'alex.wong01@testmail.com', '3957jsf'),  
(2, 'John Doe', '"0x72b39A59Ee9D5E7B2cA14C1C2a8bC4B3A7f9E5d1', 'daniel.khoo09@mockmail.com', '9473nnj'), 
(3, 'Jason', '"0x13cE72aF6D43C70B56D5Af9D91fD67Ee9b2a5e11', 'michelle.tan04@fakemail.com', '824knj2'), 
(4, 'Gabriel', '"0xa7F2b0F4c98B4E2e0B4Ff6C4fA7D81A9C43b7E5A', 'matthew.ong07@tempemail.com', 'akd292n'), 
(5, 'Andrea', '"0x8B92a3C9F8b0B1C7a3F4d6e4bA0A3D4bE8eF72c1', 'daniel.khoo09@mockmail.com', 'aj710nwj'), 
(6, 'Kylie', '0x1978564402AcFDeaCADd4FB50eBFC9576bc229D6', 'kylie.lee44@mockmail.com', 'ajsf1023'), 
(7, 'Alvin', '0x21FB3974c4Dc290a5CB392690b0444EC8662BFb7', 'alvin.khoo49@example.com', 'Gu791'), 
(8, 'Felicia', '0x772910e3F5590439e53bb2293789A5149e67c23E', 'felicia.ho16@testmail.com', 'akU80HG');

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

INSERT INTO uploaded_document (user_id, name, wallet_address, status, contract_app_id, university_college, program_of_study, expected_graduation_date, academic_achivements)
VALUES
(1, 'Jamal', '0x4f9c8B72FAbF95E3a7d6B18E4d1b9c8E2F1dA7c3', 'pending', '0x9b1bfa85fcd70dc32b1f5c7e23a5c3b6aef08d1b4cfb52491d33e8f84b3a2c5b', 'University of Malaya', 'Bachelor of Computer Science', '2026-10-01', 'Dean List 2023, Programming Competition Finalist'),  
(2, 'John Doe', '"0x72b39A59Ee9D5E7B2cA14C1C2a8bC4B3A7f9E5d1', 'pending', '0x7b8e2a6c5f78d9c8f1e2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3d4', 'Sunway University', 'Bachelor of Psychology', '2027-11-20', 'Research Paper Published in Psychology Journal'), 
(3, 'Jason', '"0x13cE72aF6D43C70B56D5Af9D91fD67Ee9b2a5e11', 'pending', '0x6c3d5b7e8f9a1b2c3d4e5f6789a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8', 'APU', 'Bachelor of Data Science', '2025-12-10', 'Hackathon Champion, Dean List 2023'), 
(4, 'Gabriel', '"0xa7F2b0F4c98B4E2e0B4Ff6C4fA7D81A9C43b7E5A', 'pending', '0xa1b2c3d4e5f6789a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9c0d1e2f3a', 'Taylor University', 'Bachelor of Business Administration', '2025-09-15"', '"Best Business Plan Award 2024'), 
(5, 'Andrea', '"0x8B92a3C9F8b0B1C7a3F4d6e4bA0A3D4bE8eF72c1', 'pending', '0xf7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6f7a8', 'INTI International University', 'Bachelor of Electrical Engineering', '2026-08-30', 'Robotics Championship Winner 2024');

CREATE TABLE IF NOT EXISTS donations (
  donation_id SERIAL PRIMARY KEY,
  name VARCHAR(200),
  wallet_address VARCHAR(42),
  amount_wei NUMERIC(38,0),
  amount_eth NUMERIC(36,18),
  tx_hash VARCHAR(100),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO uploaded_document (name, wallet_address, amount_wei, amount_eth, tx_hash)
VALUES
('Kylie', '0x1978564402AcFDeaCADd4FB50eBFC9576bc229D6', '1000000000000000000', '1.000000000000000000', '0xa8f1b0c47e6d19d9a3b2c5f2d1e9a7b0e8f2d1a6b7c8d9e0f1a2b3c4d5e6f7a8'), 
('Alvin', '0x21FB3974c4Dc290a5CB392690b0444EC8662BFb7', '2500000000000000000', '2.500000000000000000', '0x9e6b4c5a8f7d1a2e0f3b5d6c8a9b7e6d4c2b1f0e9d8c7b6a5f4e3d2c1b0a9f8e'),
('Felicia', '0x772910e3F5590439e53bb2293789A5149e67c23E', '500000000000000000', '0.500000000000000000', '0xc4e7d2a1b0f9e8d7c6b5a4f3e2d1c0b9a8f7e6d5c4b3a2f1e0d9c8b7a6f5e4d3');

CREATE TABLE IF NOT EXISTS admin_users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(50) UNIQUE,
  password TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO uploaded_document (admin_id, name, password)
VALUES
(1, 'Patrick', '3456'),  
(2, 'Timothy', '6789'),  
(3, 'Michelle', '2678');  

CREATE TABLE IF NOT EXISTS admin_actions (
  action_id SERIAL PRIMARY KEY,
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

INSERT INTO uploaded_document (app_id, file_data)
VALUES
(16, E'\\x255044462d312e350a25d0d4c5d80a'),  
(19, E'\\x89504e470d0a1a0a0000000d494844'),  
(17, E'\\x255044462d312e370a25b5b5b5b50a'),  
(20, E'\\xffd8ffe000104a4649460001010100'),  
(18, E'\\x89504e470d0a1a0a0000000d494844'); 


