DROP DATABASE IF EXISTS nhs_database;
CREATE DATABASE nhs_database;
USE nhs_database;

CREATE TABLE clinic (
    ClinicID INT AUTO_INCREMENT PRIMARY KEY,
    ClinicName VARCHAR(80) NOT NULL,
    ClinicAddress VARCHAR(160) NOT NULL,
    Phone VARCHAR(20),
    UNIQUE (ClinicName, ClinicAddress)
);

CREATE TABLE department (
    DepartmentID INT AUTO_INCREMENT PRIMARY KEY,
    DepartmentName VARCHAR(80) NOT NULL UNIQUE,
    ClinicID INT NOT NULL,
    FOREIGN KEY (ClinicID) REFERENCES clinic(ClinicID)
);

CREATE TABLE doctor (
    DoctorID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    Specialty VARCHAR(80) NOT NULL,
    Email VARCHAR(120) NOT NULL UNIQUE,
    Phone VARCHAR(20),
    ClinicID INT NOT NULL,
    DepartmentID INT,
    FOREIGN KEY (ClinicID) REFERENCES clinic(ClinicID),
    FOREIGN KEY (DepartmentID) REFERENCES department(DepartmentID)
);

CREATE TABLE patient (
    PatientID INT AUTO_INCREMENT PRIMARY KEY,
    FirstName VARCHAR(50) NOT NULL,
    LastName VARCHAR(50) NOT NULL,
    DateOfBirth DATE NOT NULL,
    Gender VARCHAR(20),
    Phone VARCHAR(20),
    Email VARCHAR(120) UNIQUE,
    Address VARCHAR(160) NOT NULL,
    PasswordHash CHAR(64)
);

CREATE TABLE appointment (
    AppointmentID INT AUTO_INCREMENT PRIMARY KEY,
    PatientID INT NOT NULL,
    DoctorID INT NOT NULL,
    ClinicID INT NOT NULL,
    AppointmentDate DATE NOT NULL,
    AppointmentTime TIME NOT NULL,
    Status VARCHAR(30) DEFAULT 'Booked',
    Notes VARCHAR(255),
    FOREIGN KEY (PatientID) REFERENCES patient(PatientID),
    FOREIGN KEY (DoctorID) REFERENCES doctor(DoctorID),
    FOREIGN KEY (ClinicID) REFERENCES clinic(ClinicID),
    UNIQUE (DoctorID, AppointmentDate, AppointmentTime)
);

CREATE TABLE medication (
    MedicationID INT AUTO_INCREMENT PRIMARY KEY,
    MedicationName VARCHAR(80) NOT NULL UNIQUE,
    Description VARCHAR(255)
);

CREATE TABLE prescription (
    PrescriptionID INT AUTO_INCREMENT PRIMARY KEY,
    PatientID INT NOT NULL,
    DoctorID INT NOT NULL,
    PrescriptionDate DATE NOT NULL,
    Notes VARCHAR(255),
    FOREIGN KEY (PatientID) REFERENCES patient(PatientID),
    FOREIGN KEY (DoctorID) REFERENCES doctor(DoctorID)
);

CREATE TABLE patientmedication (
    PatientMedicationID INT AUTO_INCREMENT PRIMARY KEY,
    PrescriptionID INT NOT NULL,
    MedicationID INT NOT NULL,
    Dosage VARCHAR(80),
    Frequency VARCHAR(80),
    FOREIGN KEY (PrescriptionID) REFERENCES prescription(PrescriptionID),
    FOREIGN KEY (MedicationID) REFERENCES medication(MedicationID),
    UNIQUE (PrescriptionID, MedicationID)
);

CREATE TABLE role (
    RoleID INT AUTO_INCREMENT PRIMARY KEY,
    RoleName VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE useraccount (
    UserID INT AUTO_INCREMENT PRIMARY KEY,
    Username VARCHAR(50) NOT NULL UNIQUE,
    PasswordHash CHAR(64) NOT NULL,
    RoleID INT NOT NULL,
    PatientID INT NULL,
    DoctorID INT NULL,
    FOREIGN KEY (RoleID) REFERENCES role(RoleID),
    FOREIGN KEY (PatientID) REFERENCES patient(PatientID),
    FOREIGN KEY (DoctorID) REFERENCES doctor(DoctorID)
);

CREATE TABLE auditlog (
    LogID INT AUTO_INCREMENT PRIMARY KEY,
    TableName VARCHAR(60) NOT NULL,
    ActionType VARCHAR(30) NOT NULL,
    RecordID INT,
    ActionDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    Description VARCHAR(255)
);

CREATE OR REPLACE VIEW PatientAppointmentsView AS
SELECT p.PatientID,
       p.FirstName AS PatientFirstName,
       p.LastName AS PatientLastName,
       d.FirstName AS DoctorFirstName,
       d.LastName AS DoctorLastName,
       c.ClinicName,
       a.AppointmentDate,
       a.AppointmentTime,
       a.Status,
       a.Notes
FROM appointment a
JOIN patient p ON a.PatientID = p.PatientID
JOIN doctor d ON a.DoctorID = d.DoctorID
JOIN clinic c ON a.ClinicID = c.ClinicID;

DELIMITER //
CREATE PROCEDURE GetPatientAppointments(IN inPatientID INT)
BEGIN
    SELECT *
    FROM PatientAppointmentsView
    WHERE PatientID = inPatientID
    ORDER BY AppointmentDate, AppointmentTime;
END //

CREATE TRIGGER trg_patient_after_insert
AFTER INSERT ON patient
FOR EACH ROW
BEGIN
    INSERT INTO auditlog(TableName, ActionType, RecordID, Description)
    VALUES ('patient', 'INSERT', NEW.PatientID,
            CONCAT('New patient added: ', NEW.FirstName, ' ', NEW.LastName));
END //
DELIMITER ;
