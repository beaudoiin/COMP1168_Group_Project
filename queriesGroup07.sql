USE abc_clinic;
--#1 Create a query that returns Patients’ full names, addresses, phone numbers and email addresses. (Ten results minimum). 
SELECT
CONCAT (first_name, ' ', last_name) AS full_name,›
address, 
phone, 
email
FROM patient 
LIMIT 10;

--#2 Create a query that lists full names of all patients and their last appointments dates who have not had any appointment in the clinic in the last 2 years (at least one patient) 
SELECT 
CONCAT(p.first_name, ' ', p.last_name) as full_name, 
MAX(a.appointment_datetime) AS last_visit
FROM patient p
JOIN appointment a ON p.patient_id=a.patient_id
GROUP BY p.patient_id
HAVING MAX(a.appointment_datetime)<DATE_SUB(CURDATE(),INTERVAl 2 YEAR);

--#3 Create a query that returns the all appointment by a particular patient in the year of 2023 (should return 5 appointments at least) the result set would include patient names, examining doctors’ and nurses’ names, dates and times of the appointments, any tests ordered by the doctors for the patient. 
SELECT
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
    CONCAT(n.first_name, ' ', n.last_name) AS nurse_name,
    a.appointment_datetime,
    lt.test_name
FROM appointment a
JOIN patient p ON a.patient_id = p.patient_id
JOIN doctor d ON a.doctor_id = d.doctor_id
LEFT JOIN visit v ON a.appointment_id = v.appointment_id
LEFT JOIN vitals vt ON v.visit_id = vt.visit_id
LEFT JOIN nurse n ON vt.nurse_id = n.nurse_id
LEFT JOIN lab_test lt ON v.visit_id = lt.visit_id
WHERE a.appointment_datetime BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY a.appointment_datetime ASC;

--#4 Create a query that returns all appointments that were either cancelled, or patients were No Show in the month of December 2023. (five results minimum) 
SELECT * 
FROM appointment 
WHERE status IN ('Cancelled', 'No Show') 
AND appointment_datetime
BETWEEN '2023-12-01' 
AND '2023-12-31' 
LIMIT 5; 

--#5 Create a query that that returns staff members’ names (excluding doctors), their hourly rates, number of hours worked and Salary (calculated column; there are 13 employees in the clinic) for the two- week period. 
SELECT 
n.nurse_id, 
CONCAT(n.first_name, ' ', n.last_name) AS staff_member, 
n.hourly_rate, 
SUM(ns.hours_worked) AS total_hours, 
(n.hourly_rate * SUM(ns.hours_worked)) AS total_salary FROM nurse n 
JOIN nurse_shift ns ON n.nurse_id = ns.nurse_id 
JOIN shift s ON ns.shift_id = s.shift_id 
WHERE s.shift_date 
BETWEEN '2023-12-01' AND '2023-12-14' 
GROUP BY  n.nurse_id,  
n.first_name,  
n.last_name,  
N.hourly_rate; 

--#6 The Clinic Manager has decided to send “Happy holidays” greeting cards to all patients and clinic staff, in December and want to print mailing labels which consist of two columns; the concatenated full names and complete addresses (concatenate the: street address, city, province, Postal Code). Please create a query that retrieves this information (usually called a mailing label) 
SELECT
CONCAT(first_name, ' ', last_name) AS full_name, address AS mailing_label
FROM patient UNION SELECT
CONCAT(first_name, ' ', last_name) AS full_name,
'ABC Walk-in Clinic, Toronto, ON, M5G 2M8' AS mailing_label FROM doctor
UNION
 
SELECT
CONCAT(first_name, ' ', last_name) AS full_name,
'ABC Walk-in Clinic, Toronto, ON, M5G 2M8' AS mailing_label FROM nurse
UNION SELECT
CONCAT(first_name, ' ', last_name) AS full_name,
'ABC Walk-in Clinic, Toronto, ON, M5G 2M8' AS mailing_label FROM secretary
UNION SELECT
CONCAT(first_name, ' ', last_name) AS full_name,
'ABC Walk-in Clinic, Toronto, ON, M5G 2M8' AS mailing_label FROM manager;

--#7 Create a query that returns all patients and their doctor’s names who enrolled permanently with any doctors in the clinic.
SELECT
CONCAT(p.first_name, ' ', p.last_name) AS patient_name, CONCAT(d.first_name, ' ', d.last_name) AS doctor_name FROM patient p
JOIN doctor d
ON p.enrolled_doctor_id = d.doctor_id Where p.is_enrolled = True

--#8 Create a query that returns a list of all patients and their family member (add a column primary member id in the patient table; make one patient as the primary member and then create another column called relationship and add husband, wife, son, daughter etc.) SELECT
CONCAT(pm.first_name, ' ', pm.last_name) AS primary_member, 
CONCAT(fm.first_name, ' ', fm.last_name) AS family_member, fm.relationship
FROM patient fm 
JOIN patient pm
ON fm.primary_member_id = pm.patient_id 
ORDER BY pm.patient_id, fm.patient_id;

--#9 Create a query that would create a list of all patients that were seen by a particular doctor on a given date (i.e. 12 December, 2022)
SELECT
CONCAT(p.first_name, ' ', p.last_name) AS patient_name, CONCAT(d.first_name, ' ', d.last_name) AS doctor_name, a.appointment_datetime
FROM appointment a JOIN patient p
ON a.patient_id = p.patient_id JOIN doctor d
ON a.doctor_id = d.doctor_id
WHERE DATE(a.appointment_datetime) = '2022-12-12';

--#10 Create a query that would return name of a patient who paid some sort of a fee to the clinic, also retrieve the service for which he paid and the doctor’s name (for example Dr Smith, Sick Note)
SELECT
CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
 
i.amount_paid,
i.description AS service_paid_for,
CONCAT(d.first_name, ' ', d.last_name) AS doctor_name FROM invoice i
JOIN patient p
ON i.patient_id = p.patient_id LEFT JOIN doctor d
ON i.doctor_id = d.doctor_id WHERE i.amount_paid > 0;

