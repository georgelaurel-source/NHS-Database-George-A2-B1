-- =============================================================
-- CPU4-103 Introduction to Database
-- NHS Database Management System
-- George Cazan - Individual Part C and Part D
-- Data manipulation, validation queries and security controls
-- Database: nhs_database
-- =============================================================

USE nhs_database;

-- =============================================================
-- PART C: INDIVIDUAL ADVANCED SQL QUERIES
-- =============================================================

-- Query 1: Aggregate function - count appointments per clinic
SELECT c.ClinicName,
       COUNT(a.AppointmentID) AS TotalAppointments
FROM clinic c
LEFT JOIN appointment a ON c.ClinicID = a.ClinicID
GROUP BY c.ClinicID, c.ClinicName
ORDER BY TotalAppointments DESC;

-- Query 2: Aggregate function - average number of appointments per doctor
SELECT ROUND(AVG(AppointmentCount), 2) AS AverageAppointmentsPerDoctor
FROM (
    SELECT d.DoctorID,
           COUNT(a.AppointmentID) AS AppointmentCount
    FROM doctor d
    LEFT JOIN appointment a ON d.DoctorID = a.DoctorID
    GROUP BY d.DoctorID
) AS doctor_totals;

-- Query 3: INNER JOIN - booked appointments with patient, doctor and clinic details
SELECT a.AppointmentID,
       CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
       CONCAT(d.FirstName, ' ', d.LastName) AS DoctorName,
       d.Specialty,
       c.ClinicName,
       a.AppointmentDate,
       a.AppointmentTime,
       a.Status
FROM appointment a
INNER JOIN patient p ON a.PatientID = p.PatientID
INNER JOIN doctor d ON a.DoctorID = d.DoctorID
INNER JOIN clinic c ON a.ClinicID = c.ClinicID
ORDER BY a.AppointmentDate, a.AppointmentTime;

-- Query 4: LEFT JOIN - patients with or without appointments
SELECT p.PatientID,
       CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
       a.AppointmentID,
       a.AppointmentDate,
       a.Status
FROM patient p
LEFT JOIN appointment a ON p.PatientID = a.PatientID
ORDER BY p.PatientID, a.AppointmentDate;

-- Query 5: FULL JOIN equivalent in MySQL using UNION
-- MySQL does not support FULL OUTER JOIN directly, so LEFT JOIN + RIGHT JOIN is used.
SELECT p.PatientID,
       CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
       a.AppointmentID,
       a.AppointmentDate,
       'LEFT SIDE' AS JoinSource
FROM patient p
LEFT JOIN appointment a ON p.PatientID = a.PatientID
UNION
SELECT p.PatientID,
       CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
       a.AppointmentID,
       a.AppointmentDate,
       'RIGHT SIDE' AS JoinSource
FROM patient p
RIGHT JOIN appointment a ON p.PatientID = a.PatientID
ORDER BY PatientID, AppointmentDate;

-- Stored procedure: retrieve all appointments for a selected doctor
DROP PROCEDURE IF EXISTS GetDoctorAppointments;
DELIMITER //
CREATE PROCEDURE GetDoctorAppointments(IN inDoctorID INT)
BEGIN
    SELECT a.AppointmentID,
           CONCAT(p.FirstName, ' ', p.LastName) AS PatientName,
           CONCAT(d.FirstName, ' ', d.LastName) AS DoctorName,
           c.ClinicName,
           a.AppointmentDate,
           a.AppointmentTime,
           a.Status,
           a.Notes
    FROM appointment a
    INNER JOIN patient p ON a.PatientID = p.PatientID
    INNER JOIN doctor d ON a.DoctorID = d.DoctorID
    INNER JOIN clinic c ON a.ClinicID = c.ClinicID
    WHERE a.DoctorID = inDoctorID
    ORDER BY a.AppointmentDate, a.AppointmentTime;
END //
DELIMITER ;

-- Test stored procedure
CALL GetDoctorAppointments(1);

-- Trigger: audit appointment status changes
DROP TRIGGER IF EXISTS trg_appointment_after_update;
DELIMITER //
CREATE TRIGGER trg_appointment_after_update
AFTER UPDATE ON appointment
FOR EACH ROW
BEGIN
    IF OLD.Status <> NEW.Status THEN
        INSERT INTO auditlog(TableName, ActionType, RecordID, Description)
        VALUES ('appointment', 'UPDATE', NEW.AppointmentID,
                CONCAT('Appointment status changed from ', OLD.Status, ' to ', NEW.Status));
    END IF;
END //
DELIMITER ;

-- Test trigger example
-- UPDATE appointment SET Status = 'Completed' WHERE AppointmentID = 1;
-- SELECT * FROM auditlog ORDER BY ActionDate DESC;

-- =============================================================
-- PART D: DATABASE SECURITY AND DATA PROTECTION
-- =============================================================

-- Create four user accounts for database access control
-- Passwords are academic examples only and should be replaced in a live system.
CREATE USER IF NOT EXISTS 'nhs_admin'@'localhost' IDENTIFIED BY 'AdminPass123!';
CREATE USER IF NOT EXISTS 'nhs_doctor'@'localhost' IDENTIFIED BY 'DoctorPass123!';
CREATE USER IF NOT EXISTS 'nhs_receptionist'@'localhost' IDENTIFIED BY 'ReceptionPass123!';
CREATE USER IF NOT EXISTS 'nhs_patient'@'localhost' IDENTIFIED BY 'PatientPass123!';

-- Administrator: full control of the database
GRANT ALL PRIVILEGES ON nhs_database.* TO 'nhs_admin'@'localhost';

-- Doctor: can view clinical data and update appointments/prescriptions
GRANT SELECT ON nhs_database.patient TO 'nhs_doctor'@'localhost';
GRANT SELECT, INSERT, UPDATE ON nhs_database.appointment TO 'nhs_doctor'@'localhost';
GRANT SELECT, INSERT, UPDATE ON nhs_database.prescription TO 'nhs_doctor'@'localhost';
GRANT SELECT, INSERT, UPDATE ON nhs_database.patientmedication TO 'nhs_doctor'@'localhost';
GRANT SELECT ON nhs_database.medication TO 'nhs_doctor'@'localhost';
GRANT SELECT ON nhs_database.PatientAppointmentsView TO 'nhs_doctor'@'localhost';

-- Receptionist: can manage appointment bookings but not sensitive clinical notes
GRANT SELECT ON nhs_database.patient TO 'nhs_receptionist'@'localhost';
GRANT SELECT, INSERT, UPDATE ON nhs_database.appointment TO 'nhs_receptionist'@'localhost';
GRANT SELECT ON nhs_database.doctor TO 'nhs_receptionist'@'localhost';
GRANT SELECT ON nhs_database.clinic TO 'nhs_receptionist'@'localhost';

-- Patient: limited read-only access to appointment view
GRANT SELECT ON nhs_database.PatientAppointmentsView TO 'nhs_patient'@'localhost';

-- Apply privilege changes
FLUSH PRIVILEGES;

-- Data protection example: store a password as a SHA2 hash rather than plain text
UPDATE patient
SET PasswordHash = SHA2(CONCAT(FirstName, LastName, PatientID, 'NHS2026'), 256)
WHERE PasswordHash IS NULL;

-- Check grants for evidence screenshots
SHOW GRANTS FOR 'nhs_admin'@'localhost';
SHOW GRANTS FOR 'nhs_doctor'@'localhost';
SHOW GRANTS FOR 'nhs_receptionist'@'localhost';
SHOW GRANTS FOR 'nhs_patient'@'localhost';
