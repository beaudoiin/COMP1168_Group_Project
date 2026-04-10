DROP DATABASE IF EXISTS abc_clinic;
CREATE DATABASE abc_clinic;
USE abc_clinic;

-- ============================================
-- ABC WALK-IN CLINIC DATABASE SCHEMA
-- Physical Database
-- ============================================

-- Drop tables if they exist (for clean re-creation)
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS invoice;
DROP TABLE IF EXISTS appointment;
DROP TABLE IF EXISTS visit_specialist;
DROP TABLE IF EXISTS nurse_shift;
DROP TABLE IF EXISTS secretary_shift;
DROP TABLE IF EXISTS shift_payroll;
DROP TABLE IF EXISTS vitals;
DROP TABLE IF EXISTS diagnosis;
DROP TABLE IF EXISTS lab_test;
DROP TABLE IF EXISTS visit;
DROP TABLE IF EXISTS patient;
DROP TABLE IF EXISTS doctor;
DROP TABLE IF EXISTS nurse;
DROP TABLE IF EXISTS secretary;
DROP TABLE IF EXISTS shift;
DROP TABLE IF EXISTS specialist;
DROP TABLE IF EXISTS manager;
DROP TABLE IF EXISTS payroll;

SET FOREIGN_KEY_CHECKS = 1;

-- ============================================
-- CORE ENTITIES
-- ============================================

-- PATIENT table
CREATE TABLE patient (
    patient_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE NOT NULL,
    address VARCHAR(200),
    phone VARCHAR(20),
    email VARCHAR(100),
    health_card_number VARCHAR(20) UNIQUE NOT NULL,
    is_enrolled BOOLEAN DEFAULT FALSE,
    enrolled_doctor_id INT,
    primary_member_id INT NULL, 
    relationship VARCHAR(50) NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
ALTER TABLE patient 
ADD CONSTRAINT fk_patient_primary_member
FOREIGN KEY (primary_member_id)
REFERENCES patient(patient_id) ON DELETE SET NULL;


-- DOCTOR table
CREATE TABLE doctor (
    doctor_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    specialization VARCHAR(100),
    license_number VARCHAR(50) UNIQUE,
    phone VARCHAR(20),
    email VARCHAR(100)
);

-- NURSE table
CREATE TABLE nurse (
    nurse_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    license_number VARCHAR(50) UNIQUE,
    phone VARCHAR(20),
    email VARCHAR(100),
    hourly_rate DECIMAL(10,2) DEFAULT 35.00
);

-- SECRETARY table
CREATE TABLE secretary (
    secretary_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    hourly_rate DECIMAL(10,2) DEFAULT 25.00
);

-- MANAGER table
CREATE TABLE manager (
    manager_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100),
    hire_date DATE
);

-- SPECIALIST table
CREATE TABLE specialist (
    specialist_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100) NOT NULL,
    specialty_area VARCHAR(100),
    clinic_name VARCHAR(100),
    phone VARCHAR(20),
    address VARCHAR(200)
);

-- SHIFT table
CREATE TABLE shift (
    shift_id INT PRIMARY KEY AUTO_INCREMENT,
    shift_date DATE NOT NULL,
    shift_time ENUM('7am-2pm', '2pm-8pm') NOT NULL,
    start_time TIME NOT NULL,
    end_time TIME NOT NULL,
    UNIQUE KEY unique_shift (shift_date, shift_time)
);

-- ============================================
-- VISIT AND RELATED TABLES
-- ============================================

-- VISIT table (core transaction table)
CREATE TABLE visit (
    visit_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    appointment_id INT NULL,
    visit_datetime DATETIME NOT NULL,
    visit_type ENUM('walk-in', 'enrolled') NOT NULL,
    check_in_time DATETIME,
    check_out_time DATETIME,
    status ENUM('checked_in', 'checked_out', 'LWT', 'no_show') DEFAULT 'checked_in',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE
);

-- INVOICE table
CREATE TABLE invoice (
    invoice_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    doctor_id INT NULL, 
    invoice_date DATE NOT NULL,
    amount_owed DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    amount_paid DECIMAL(10,2) DEFAULT 0.00,
    is_paid BOOLEAN DEFAULT FALSE,
    description VARCHAR(255),
    FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id) ON DELETE SET NULL
);

-- APPOINTMENT table
CREATE TABLE appointment (
    appointment_id INT PRIMARY KEY AUTO_INCREMENT,
    patient_id INT NOT NULL,
    doctor_id INT NOT NULL,
    secretary_id INT NULL,
    appointment_datetime DATETIME NOT NULL,
    status ENUM('booked', 'cancelled', 'arrived', 'checked_in', 'checked_out', 'LWT', 'no_show') DEFAULT 'booked',
    cancellation_fee DECIMAL(10,2) DEFAULT 0.00,
    cancellation_reason VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES patient(patient_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (secretary_id) REFERENCES secretary(secretary_id) ON DELETE SET NULL
);

-- VITALS table
CREATE TABLE vitals (
    vitals_id INT PRIMARY KEY AUTO_INCREMENT,
    visit_id INT NOT NULL UNIQUE,
    nurse_id INT NOT NULL,
    blood_pressure VARCHAR(20),
    temperature DECIMAL(4,1),
    height DECIMAL(5,2),
    weight DECIMAL(5,2),
    symptoms_notes TEXT,
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (visit_id) REFERENCES visit(visit_id) ON DELETE CASCADE,
    FOREIGN KEY (nurse_id) REFERENCES nurse(nurse_id) ON DELETE CASCADE
);

-- DIAGNOSIS table
CREATE TABLE diagnosis (
    diagnosis_id INT PRIMARY KEY AUTO_INCREMENT,
    visit_id INT NOT NULL UNIQUE,
    doctor_id INT NOT NULL,
    diagnosis_text TEXT NOT NULL,
    treatment TEXT,
    prescription TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (visit_id) REFERENCES visit(visit_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id) ON DELETE CASCADE
);

-- LAB TEST table
CREATE TABLE lab_test (
    lab_test_id INT PRIMARY KEY AUTO_INCREMENT,
    visit_id INT NOT NULL,
    doctor_id INT NOT NULL,
    reviewed_by_nurse_id INT NULL,
    test_type ENUM('blood work', 'XRAY', 'Ultrasound', 'other') NOT NULL,
    test_name VARCHAR(100),
    status ENUM('ordered', 'completed', 'reviewed') DEFAULT 'ordered',
    results TEXT,
    ordered_date DATE NOT NULL,
    completed_date DATE,
    reviewed_date DATE,
    FOREIGN KEY (visit_id) REFERENCES visit(visit_id) ON DELETE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES doctor(doctor_id) ON DELETE CASCADE,
    FOREIGN KEY (reviewed_by_nurse_id) REFERENCES nurse(nurse_id) ON DELETE SET NULL
);

-- ============================================
-- MANY-TO-MANY (M:N) RELATIONSHIP TABLES
-- ============================================

-- VISIT to SPECIALIST (M:N) - referrals
CREATE TABLE visit_specialist (
    visit_specialist_id INT PRIMARY KEY AUTO_INCREMENT,
    visit_id INT NOT NULL,
    specialist_id INT NOT NULL,
    referral_date DATE NOT NULL,
    referral_notes TEXT,
    follow_up_needed BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (visit_id) REFERENCES visit(visit_id) ON DELETE CASCADE,
    FOREIGN KEY (specialist_id) REFERENCES specialist(specialist_id) ON DELETE CASCADE,
    UNIQUE KEY unique_visit_specialist (visit_id, specialist_id)
);

-- NURSE to SHIFT (M:N)
CREATE TABLE nurse_shift (
    nurse_shift_id INT PRIMARY KEY AUTO_INCREMENT,
    nurse_id INT NOT NULL,
    shift_id INT NOT NULL,
    hours_worked DECIMAL(5,2) DEFAULT 6.00,
    actual_check_in TIME,
    actual_check_out TIME,
    FOREIGN KEY (nurse_id) REFERENCES nurse(nurse_id) ON DELETE CASCADE,
    FOREIGN KEY (shift_id) REFERENCES shift(shift_id) ON DELETE CASCADE,
    UNIQUE KEY unique_nurse_shift (nurse_id, shift_id)
);

-- SECRETARY to SHIFT (M:N)
CREATE TABLE secretary_shift (
    secretary_shift_id INT PRIMARY KEY AUTO_INCREMENT,
    secretary_id INT NOT NULL,
    shift_id INT NOT NULL,
    hours_worked DECIMAL(5,2) DEFAULT 6.00,
    actual_check_in TIME,
    actual_check_out TIME,
    FOREIGN KEY (secretary_id) REFERENCES secretary(secretary_id) ON DELETE CASCADE,
    FOREIGN KEY (shift_id) REFERENCES shift(shift_id) ON DELETE CASCADE,
    UNIQUE KEY unique_secretary_shift (secretary_id, shift_id)
);

-- ============================================
-- PAYROLL TABLE
-- ============================================

-- PAYROLL table
CREATE TABLE payroll (
    payroll_id INT PRIMARY KEY AUTO_INCREMENT,
    manager_id INT NOT NULL,
    payroll_period_start DATE NOT NULL,
    payroll_period_end DATE NOT NULL,
    generated_date DATE NOT NULL,
    FOREIGN KEY (manager_id) REFERENCES manager(manager_id) ON DELETE CASCADE
);

-- SHIFT to PAYROLL (M:N) - which shifts are included in which payroll
CREATE TABLE shift_payroll (
    shift_payroll_id INT PRIMARY KEY AUTO_INCREMENT,
    shift_id INT NOT NULL,
    payroll_id INT NOT NULL,
    FOREIGN KEY (shift_id) REFERENCES shift(shift_id) ON DELETE CASCADE,
    FOREIGN KEY (payroll_id) REFERENCES payroll(payroll_id) ON DELETE CASCADE,
    UNIQUE KEY unique_shift_payroll (shift_id, payroll_id)
);

-- ============================================
-- ADD FOREIGN KEY CONSTRAINTS (for patient-enrolled doctor)
-- ============================================

ALTER TABLE patient 
ADD CONSTRAINT fk_patient_enrolled_doctor 
FOREIGN KEY (enrolled_doctor_id) 
REFERENCES doctor(doctor_id) ON DELETE SET NULL;

ALTER TABLE visit
ADD CONSTRAINT fk_visit_appointment
FOREIGN KEY (appointment_id)
REFERENCES appointment(appointment_id) ON DELETE SET NULL;

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================

CREATE INDEX idx_patient_lastname ON patient(last_name);
CREATE INDEX idx_patient_healthcard ON patient(health_card_number);
CREATE INDEX idx_visit_patient ON visit(patient_id);
CREATE INDEX idx_visit_datetime ON visit(visit_datetime);
CREATE INDEX idx_appointment_datetime ON appointment(appointment_datetime);
CREATE INDEX idx_appointment_patient ON appointment(patient_id);
CREATE INDEX idx_appointment_doctor ON appointment(doctor_id);
CREATE INDEX idx_lab_test_visit ON lab_test(visit_id);
CREATE INDEX idx_shift_date ON shift(shift_date);
CREATE INDEX idx_payroll_period ON payroll(payroll_period_start, payroll_period_end);

-- ============================================
-- INSERT SAMPLE DATA 
-- ============================================

-- Insert a manager
INSERT INTO manager (first_name, last_name, phone, email, hire_date) 
VALUES ('John', 'Smith', '555-0101', 'john.smith@clinic.com', '2020-01-15');

-- Insert a doctor
INSERT INTO doctor (first_name, last_name, specialization, license_number, phone, email) 
VALUES ('Sarah', 'Johnson', 'Family Medicine', 'DOC12345', '416-555-0201', 'sarah.johnson@abcclinic.com'),
('Michael', 'Chen', 'Family Medicine', 'DOC12346', '416-555-0202', 'michael.chen@abcclinic.com'),
('Emily', 'Patel', 'Pediatrics', 'DOC12347', '416-555-0203', 'emily.patel@abcclinic.com'),
('David', 'Okonkwo', 'Internal Medicine', 'DOC12348', '416-555-0204', 'david.okonkwo@abcclinic.com'),
('Jennifer', 'Martinez', 'Geriatrics', 'DOC12349', '416-555-0205', 'jennifer.martinez@abcclinic.com'),
('Robert', 'Kim', 'Cardiology', 'DOC12350', '416-555-0206', 'robert.kim@abcclinic.com'),
('Lisa', 'Wong', 'Dermatology', 'DOC12351', '416-555-0207', 'lisa.wong@abcclinic.com'),
('James', 'Wilson', 'Neurology', 'DOC12352', '416-555-0208', 'james.wilson@abcclinic.com'),
('Maria', 'Garcia', 'Obstetrics & Gynecology', 'DOC12353', '416-555-0209', 'maria.garcia@abcclinic.com'),
('Thomas', 'Lee', 'Orthopedics', 'DOC12354', '416-555-0210', 'thomas.lee@abcclinic.com');


-- Insert a patient
INSERT INTO patient (first_name, last_name, date_of_birth, address, phone, email, health_card_number, is_enrolled, enrolled_doctor_id) 
VALUES ('Michael', 'Brown', '1985-06-15', '123 Main St, Toronto, ON', '555-0303', 'michael.brown@email.com', 'HC123456789', TRUE, 1),
('Sarah', 'Chen', '1990-03-22', '456 Queen St W, Toronto, ON M6J 1H1', '647-555-2002', 'sarah.chen@email.com', 'HC100002', TRUE, 1),
('David', 'Okafor', '1978-11-08', '789 Bloor St E, Toronto, ON M4W 1G9', '416-555-3003', 'david.okafor@email.com', 'HC100003', TRUE, 2),
('Emma', 'Wilson', '1995-07-14', '321 King St W, Toronto, ON M5V 1K1', '647-555-4004', 'emma.wilson@email.com', 'HC100004', FALSE, NULL),
('James', 'Martinez', '1982-09-30', '654 Danforth Ave, Toronto, ON M4J 1L5', '416-555-5005', 'james.martinez@email.com', 'HC100005', TRUE, 2),
('Olivia', 'Singh', '2000-01-17', '987 Spadina Ave, Toronto, ON M5S 2H8', '647-555-6006', 'olivia.singh@email.com', 'HC100006', FALSE, NULL),
('William', 'Thompson', '1973-05-25', '147 Yonge St, Toronto, ON M5C 1W1', '416-555-7007', 'william.thompson@email.com', 'HC100007', TRUE, 3),
('Sophia', 'Garcia', '1988-12-03', '258 College St, Toronto, ON M5T 1R5', '647-555-8008', 'sophia.garcia@email.com', 'HC100008', TRUE, 3),
('Liam', 'Kowalski', '1992-04-19', '369 Dundas St W, Toronto, ON M5T 1G2', '416-555-9009', 'liam.kowalski@email.com', 'HC100009', FALSE, NULL),
('Ava', 'Leblanc', '1969-08-27', '741 Bay St, Toronto, ON M5G 2M8', '647-555-1010', 'ava.leblanc@email.com', 'HC100010', TRUE, 4);

UPDATE patient SET primary_member_id = 1, relationship = "Self" WHERE patient_id = 1;
UPDATE patient SET primary_member_id = 1, relationship = 'Wife' WHERE patient_id = 2;
UPDATE patient SET primary_member_id = 1, relationship = 'Son' WHERE patient_id = 3;

UPDATE patient SET primary_member_id = 4, relationship = 'Self' WHERE patient_id = 4;
UPDATE patient SET primary_member_id = 4, relationship = 'Daughter' WHERE patient_id = 6;

-- Insert a nurse
INSERT INTO nurse (first_name, last_name, license_number, phone, email, hourly_rate) 
VALUES ('Emily', 'Davis', 'NUR50001', '416-555-0301', 'emily.davis@abcclinic.com', 35.00),
('Jessica', 'Miller', 'NUR50002', '416-555-0302', 'jessica.miller@abcclinic.com', 35.00),
('Amanda', 'Rodriguez', 'NUR50003', '416-555-0303', 'amanda.rodriguez@abcclinic.com', 38.00),
('Stephanie', 'Williams', 'NUR50004', '416-555-0304', 'stephanie.williams@abcclinic.com', 35.00),
('Christopher', 'Brown', 'NUR50005', '416-555-0305', 'christopher.brown@abcclinic.com', 40.00),
('Jennifer', 'Jones', 'NUR50006', '416-555-0306', 'jennifer.jones@abcclinic.com', 35.00),
('Matthew', 'Garcia', 'NUR50007', '416-555-0307', 'matthew.garcia@abcclinic.com', 37.00),
('Ashley', 'Martinez', 'NUR50008', '416-555-0308', 'ashley.martinez@abcclinic.com', 36.00),
('Joshua', 'Johnson', 'NUR50009', '416-555-0309', 'joshua.johnson@abcclinic.com', 35.00),
('Megan', 'Thomas', 'NUR50010', '416-555-0310', 'megan.thomas@abcclinic.com', 39.00);

-- Insert a secretary
INSERT INTO secretary (first_name, last_name, phone, email, hourly_rate) 
VALUES ('Lisa', 'Wilson', '416-555-0401', 'lisa.wilson@abcclinic.com', 25.00),
('Karen', 'Thompson', '416-555-0402', 'karen.thompson@abcclinic.com', 26.00),
('Nancy', 'Anderson', '416-555-0403', 'nancy.anderson@abcclinic.com', 25.00),
('Patricia', 'White', '416-555-0404', 'patricia.white@abcclinic.com', 27.00),
('Laura', 'Harris', '416-555-0405', 'laura.harris@abcclinic.com', 25.00),
('Michelle', 'Martin', '416-555-0406', 'michelle.martin@abcclinic.com', 26.00),
('Sarah', 'Robinson', '416-555-0407', 'sarah.robinson@abcclinic.com', 25.00),
('Kimberly', 'Clark', '416-555-0408', 'kimberly.clark@abcclinic.com', 28.00),
('Angela', 'Lewis', '416-555-0409', 'angela.lewis@abcclinic.com', 25.00),
('Brenda', 'Walker', '416-555-0410', 'brenda.walker@abcclinic.com', 27.00);

-- Insert appointments
INSERT INTO appointment
(patient_id, doctor_id, secretary_id, appointment_datetime, status, cancellation_fee, cancellation_reason)
VALUES 
(1, 1, 1, '2023-01-18 09:00:00', 'checked_out', 0.00, NULL),
(1, 1, 2, '2023-03-22 10:30:00', 'checked_out', 0.00, NULL),
(1, 1, 1, '2023-06-14 14:00:00', 'checked_out', 0.00, NULL),
(1, 1, 3, '2023-09-07 11:15:00', 'checked_out', 0.00, NULL),
(1, 1, 2, '2023-11-29 15:45:00', 'checked_out', 0.00, NULL),

(2, 2, 1, '2023-12-03 09:30:00', 'cancelled', 0.00, 'Patient cancelled in advance'),
(3, 2, 2, '2023-12-08 13:00:00', 'no_show', 50.00, 'No show'),
(4, 3, 3, '2023-12-12 10:00:00', 'cancelled', 50.00, 'Cancelled less than 24 hours before'),
(5, 4, 1, '2023-12-18 16:00:00', 'no_show', 50.00, 'No show'),
(6, 1, 2, '2023-12-22 08:45:00', 'cancelled', 0.00, 'Patient rescheduled'),

(7, 4, 1, '2022-12-12 10:30:00', 'checked_out', 0.00, NULL);


-- Insert a shift
INSERT INTO shift (shift_date, shift_time, start_time, end_time) 
VALUES ('2026-04-04', '7am-2pm', '07:00:00', '14:00:00'),
('2026-04-04', '2pm-8pm', '14:00:00', '20:00:00'),
('2026-04-05', '7am-2pm', '07:00:00', '14:00:00'),
('2026-04-05', '2pm-8pm', '14:00:00', '20:00:00'),
('2026-04-06', '7am-2pm', '07:00:00', '14:00:00'),
('2026-04-06', '2pm-8pm', '14:00:00', '20:00:00'),
('2026-04-07', '7am-2pm', '07:00:00', '14:00:00'),
('2026-04-07', '2pm-8pm', '14:00:00', '20:00:00'),
('2026-04-08', '7am-2pm', '07:00:00', '14:00:00'),
('2026-04-08', '2pm-8pm', '14:00:00', '20:00:00');

-- Insert a visit

INSERT INTO visit (patient_id, appointment_id, visit_datetime, visit_type, check_in_time, check_out_time, status) 
VALUES (1, 1, '2023-01-18 09:00:00', 'enrolled', '2023-01-18 08:55:00', '2023-01-18 09:35:00', 'checked_out'),
(1, 2, '2023-03-22 10:30:00', 'enrolled', '2023-03-22 10:25:00', '2023-03-22 11:05:00', 'checked_out'),
(1, 3, '2023-06-14 14:00:00', 'enrolled', '2023-06-14 13:55:00', '2023-06-14 14:40:00', 'checked_out'),
(1, 4, '2023-09-07 11:15:00', 'enrolled', '2023-09-07 11:10:00', '2023-09-07 11:50:00', 'checked_out'),
(1, 5, '2023-11-29 15:45:00', 'enrolled', '2023-11-29 15:40:00', '2023-11-29 16:20:00', 'checked_out'),
(7, 11, '2022-12-12 10:30:00', 'enrolled', '2022-12-12 10:20:00', '2022-12-12 11:05:00', 'checked_out'),
(1, NULL, '2026-04-04 10:30:00', 'enrolled', '2026-04-04 10:30:00', NULL, 'checked_in'),
(2, NULL, '2026-04-04 14:15:00', 'walk-in', '2026-04-04 14:15:00', '2026-04-04 14:50:00', 'checked_out'),
(3, NULL, '2026-04-05 09:00:00', 'enrolled', '2026-04-05 08:55:00', '2026-04-05 09:45:00', 'checked_out'),
(4, NULL, '2026-04-05 13:30:00', 'walk-in', '2026-04-05 13:30:00', '2026-04-05 14:20:00', 'checked_out'),
(5, NULL, '2026-04-06 11:00:00', 'enrolled', '2026-04-06 10:55:00', '2026-04-06 11:30:00', 'checked_out'),
(6, NULL, '2026-04-06 15:45:00', 'walk-in', '2026-04-06 15:45:00', NULL, 'LWT'),
(7, NULL, '2026-04-07 08:30:00', 'enrolled', '2026-04-07 08:25:00', '2026-04-07 09:15:00', 'checked_out'),
(8, NULL, '2026-04-07 16:00:00', 'walk-in', '2026-04-07 16:00:00', '2026-04-07 16:45:00', 'checked_out'),
(9, NULL, '2026-04-08 10:00:00', 'enrolled', '2026-04-08 09:55:00', '2026-04-08 10:40:00', 'checked_out'),
(10, NULL, '2026-04-08 14:30:00', 'walk-in', '2026-04-08 14:30:00', NULL, 'checked_in');


-- Insert vitals
INSERT INTO vitals (visit_id, nurse_id, blood_pressure, temperature, height, weight, symptoms_notes) 
VALUES (1, 1, '120/80', 98.6, 175.5, 80.2, 'Patient reports mild headache and fatigue'),
(2, 2, '118/76', 98.4, 162.3, 58.5, 'Routine checkup, no major complaints'),
(3, 3, '135/85', 99.1, 180.0, 95.5, 'Lower back pain, difficulty standing for long periods'),
(4, 4, '122/78', 98.8, 168.0, 72.0, 'Seasonal allergies, sneezing and itchy eyes'),
(5, 5, '140/90', 99.3, 182.5, 110.0, 'Shortness of breath after climbing stairs'),
(6, 1, '115/72', 98.5, 165.0, 65.5, 'Skin rash on arms and legs, itching since 3 days'),
(7, 2, '128/82', 98.9, 170.0, 78.5, 'Persistent cough and sore throat for 1 week'),
(8, 3, '110/68', 98.2, 158.0, 55.0, 'Annual physical exam, feeling healthy'),
(9, 4, '125/80', 98.7, 172.0, 82.0, 'Joint pain in knees, worse in the morning'),
(10, 5, '130/84', 99.0, 168.5, 75.5, 'Chest discomfort when exercising, no prior history'),
(11, 1, '121/79', 98.6, 175.5, 80.0, 'Seasonal cough and fatigue'),
(12, 2, '124/82', 98.7, 175.5, 80.4, 'Persistent headache for 3 days'),
(13, 3, '118/76', 98.5, 175.5, 79.8, 'Follow-up for blood pressure'),
(14, 1, '126/80', 98.8, 175.5, 80.1, 'Medication review'),
(15, 2, '122/78', 98.4, 175.5, 79.9, 'Joint stiffness in the morning'),
(16, 4, '130/84', 99.0, 170.0, 78.5, 'Cough and chest congestion');


-- Insert diagnosis
INSERT INTO diagnosis (visit_id, doctor_id, diagnosis_text, treatment, prescription) 
VALUES (1, 1, 'Common cold / Viral infection', 'Rest and hydration', 'Over-the-counter pain reliever as needed'),
(2, 1, 'Acute pharyngitis', 'Salt water gargles, rest, increase fluid intake', 'Over-the-counter lozenges and ibuprofen 400mg as needed'),
(3, 2, 'Lumbar muscle strain', 'Physical therapy referral, avoid heavy lifting, apply heat/cold packs', 'Cyclobenzaprine 5mg three times daily for 5 days'),
(4, 2, 'Seasonal allergic rhinitis', 'Avoid allergens, use air purifier, nasal saline rinse', 'Cetirizine 10mg daily for 14 days'),
(5, 3, 'Essential hypertension - Stage 1', 'Lifestyle modifications: low sodium diet, exercise 30min daily, follow-up in 3 months', 'Lisinopril 10mg once daily'),
(6, 3, 'Contact dermatitis', 'Identify and avoid trigger, apply cool compresses, use gentle soap', 'Hydrocortisone 1% cream twice daily for 7 days'),
(7, 4, 'Acute bronchitis', 'Rest, increase fluids, use humidifier, avoid smoke', 'Azithromycin 500mg on day 1 then 250mg days 2-5'),
(8, 4, 'Anxiety with insomnia', 'Cognitive behavioral therapy referral, sleep hygiene education, stress management techniques', 'Sertraline 50mg once daily, Trazodone 50mg at bedtime as needed'),
(9, 1, 'Osteoarthritis of knees', 'Physiotherapy referral, weight management program, low-impact exercises (swimming, cycling)', 'Naproxen 250mg twice daily with food'),
(10, 2, 'Gastroesophageal reflux disease (GERD)', 'Elevate head of bed, avoid spicy/fatty foods, eat smaller meals, no eating 3 hours before bedtime', 'Omeprazole 20mg once daily before breakfast for 30 days'),
(11, 1, 'Upper respiratory tract infection', 'Rest, fluids, monitor symptoms', 'Acetaminophen as needed'),
(12, 1, 'Tension headache', 'Hydration and rest', 'Ibuprofen 400mg as needed'),
(13, 1, 'Mild hypertension follow-up', 'Continue lifestyle changes', 'Continue existing medication'),
(14, 1, 'Routine medication review', 'Maintain current treatment plan', 'Prescription renewed'),
(15, 1, 'Early osteoarthritis symptoms', 'Exercise and physiotherapy advice', 'Naproxen as needed'),
(16, 4, 'Acute bronchitis', 'Rest and hydration', 'Azithromycin course');


-- Insert lab tests for appointment based visits
INSERT INTO lab_test (visit_id, doctor_id, reviewed_by_nurse_id, test_type, test_name, status, results, ordered_date, completed_date, reviewed_date)
VALUES (11, 1, 1, 'blood work', 'CBC', 'reviewed', 'Normal CBC results', '2023-01-18', '2023-01-20', '2023-01-21'),
(12, 1, 2, 'XRAY', 'Sinus X-Ray', 'reviewed', 'No acute findings', '2023-03-22', '2023-03-24', '2023-03-25'),
(13, 1, 3, 'blood work', 'Lipid Panel', 'reviewed', 'Borderline cholesterol', '2023-06-14', '2023-06-16', '2023-06-17'),
(14, 1, 1, 'Ultrasound', 'Abdominal Ultrasound', 'reviewed', 'Unremarkable study', '2023-09-07', '2023-09-10', '2023-09-11'),
(15, 1, 2, 'blood work', 'Inflammatory Markers', 'reviewed', 'Mild elevation noted', '2023-11-29', '2023-12-01', '2023-12-02');


-- Insert invoice
INSERT INTO invoice 
(patient_id, doctor_id, invoice_date, amount_owed, amount_paid, is_paid, description) 
VALUES 
(1, 1, CURDATE(), 0.00, 0.00, TRUE, 'No charge - covered by OHIP'),
(2, 1, '2026-04-01', 50.00, 50.00, TRUE, 'Cancellation fee for missed appointment (less than 24h notice)'),
(3, 2, '2026-04-02', 20.00, 20.00, TRUE, 'Sick note for work absence - 3 days'),
(4, 3, '2026-04-03', 0.00, 0.00, TRUE, 'Routine physical exam - fully covered by OHIP'),
(5, 4, '2026-04-04', 75.00, 75.00, TRUE, 'Driver medical examination form completion'),
(6, 1, '2026-04-05', 30.00, 0.00, FALSE, 'Insurance form completion (pending payment)'),
(7, 2, '2026-04-06', 0.00, 0.00, TRUE, 'Vaccination administration - covered by OHIP'),
(8, 3, '2026-04-07', 100.00, 100.00, TRUE, 'Pre-employment medical examination'),
(9, 4, '2026-04-08', 15.00, 15.00, TRUE, 'Prescription renewal without visit - administrative fee'),
(10, 5, '2026-04-09', 200.00, 100.00, FALSE, 'Uninsured visitor consultation (partial payment received)');

-- Insert payroll
INSERT INTO payroll (manager_id, payroll_period_start, payroll_period_end, generated_date) 
VALUES (1, '2026-03-21', '2026-04-03', CURDATE()),
(1, '2026-04-04', '2026-04-17', '2026-04-18'),
(1, '2026-04-18', '2026-05-01', '2026-05-02'),
(1, '2026-05-02', '2026-05-15', '2026-05-16'),
(1, '2026-05-16', '2026-05-29', '2026-05-30'),
(1, '2026-05-30', '2026-06-12', '2026-06-13'),
(1, '2026-06-13', '2026-06-26', '2026-06-27'),
(1, '2026-06-27', '2026-07-10', '2026-07-11'),
(1, '2026-07-11', '2026-07-24', '2026-07-25'),
(1, '2026-07-25', '2026-08-07', '2026-08-08');

-- ============================================
-- VIEWS FOR COMMON QUERIES
-- ============================================

-- View: Patient visit history with diagnosis
CREATE OR REPLACE VIEW patient_visit_history AS
SELECT 
    p.patient_id,
    p.first_name,
    p.last_name,
    v.visit_datetime,
    v.visit_type,
    d.diagnosis_text,
    d.treatment,
    doc.first_name AS doctor_first_name,
    doc.last_name AS doctor_last_name
FROM patient p
JOIN visit v ON p.patient_id = v.patient_id
LEFT JOIN diagnosis d ON v.visit_id = d.visit_id
LEFT JOIN doctor doc ON d.doctor_id = doc.doctor_id
ORDER BY v.visit_datetime DESC;

-- View: Bi-weekly payroll calculation for nurses
CREATE OR REPLACE VIEW nurse_payroll_view AS
SELECT 
    n.nurse_id,
    n.first_name,
    n.last_name,
    n.hourly_rate,
    SUM(ns.hours_worked) AS total_hours,
    SUM(ns.hours_worked) * n.hourly_rate AS total_pay
FROM nurse n
JOIN nurse_shift ns ON n.nurse_id = ns.nurse_id
JOIN shift s ON ns.shift_id = s.shift_id
WHERE s.shift_date BETWEEN '2026-03-21' AND '2026-04-03'
GROUP BY n.nurse_id;

-- View: Daily appointment schedule
CREATE OR REPLACE VIEW daily_appointments AS
SELECT 
    a.appointment_datetime,
    p.first_name AS patient_first,
    p.last_name AS patient_last,
    d.first_name AS doctor_first,
    d.last_name AS doctor_last,
    a.status
FROM appointment a
JOIN patient p ON a.patient_id = p.patient_id
JOIN doctor d ON a.doctor_id = d.doctor_id
ORDER BY a.appointment_datetime;

-- ============================================
-- END OF SCRIPT
-- ============================================