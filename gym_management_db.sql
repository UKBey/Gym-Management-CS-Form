-- Table: membershipplans
CREATE TABLE IF NOT EXISTS membershipplans (
  planid SERIAL PRIMARY KEY,
  planname VARCHAR(50) NOT NULL,
  price NUMERIC(10,2) NOT NULL,
  durationmonths INTEGER NOT NULL
);
-- Table: members
CREATE TABLE IF NOT EXISTS members (
  memberid SERIAL PRIMARY KEY,
  birthdate VARCHAR(25) NOT NULL,
  email VARCHAR(50) UNIQUE NOT NULL,
  firstname VARCHAR(30) NOT NULL,
  lastname VARCHAR(30) NOT NULL,
  joindate DATE NOT NULL DEFAULT CURRENT_DATE,
  phonenumber BIGINT UNIQUE NOT NULL,
  membershipplans_planid INTEGER NOT NULL,
  FOREIGN KEY (membershipplans_planid) REFERENCES membershipplans(planid)
);
-- Table: staff(SuperClass)
CREATE TABLE IF NOT EXISTS staff (
  staffid SERIAL PRIMARY KEY,
  firstname VARCHAR(30) NOT NULL,
  lastname VARCHAR(30) NOT NULL,
  phonenumber BIGINT UNIQUE NOT NULL,
  workinghours VARCHAR(20) NOT NULL,
  salary INT NOT NULL
);
-- Table: trainers(SubClass)
CREATE TABLE IF NOT EXISTS trainers (
    trainerid SERIAL PRIMARY KEY,
    specialization VARCHAR(45) NOT NULL
) INHERITS(staff);
-- Table: cleaners(SubClass)
CREATE TABLE IF NOT EXISTS cleaners (
    cleanerid SERIAL PRIMARY KEY,
    cleaningarea VARCHAR(45)
) INHERITS(staff);
-- Table: classes
CREATE TABLE IF NOT EXISTS classes (
  classid SERIAL PRIMARY KEY,
  classdate DATE NOT NULL DEFAULT CURRENT_DATE,
  classname VARCHAR(50) NOT NULL,
  classtime VARCHAR(20) NOT NULL,
  duration INTEGER NOT NULL,
  maxparticipants INTEGER NOT NULL,
  trainers_trainerid INTEGER NOT NULL,
  students_count INTEGER DEFAULT 0,
  FOREIGN KEY (trainers_trainerid) REFERENCES trainers(trainerid)
);
-- Table: attendance
CREATE TABLE IF NOT EXISTS attendance (
  attendanceid SERIAL PRIMARY KEY,
  attendancedate DATE NOT NULL DEFAULT CURRENT_DATE,
  members_memberid INTEGER NOT NULL,
  classes_classid INTEGER NOT NULL,
  FOREIGN KEY (members_memberid) REFERENCES members(memberid),
  FOREIGN KEY (classes_classid) REFERENCES classes(classid)
);
-- Table: payments
CREATE TABLE IF NOT EXISTS payments (
  paymentid SERIAL PRIMARY KEY,
  amount NUMERIC(10,2) NOT NULL,
  paymentdate DATE NOT NULL,
  members_memberid INTEGER NOT NULL,
  FOREIGN KEY (members_memberid) REFERENCES members(memberid)
);
-- Table: enrollments
CREATE TABLE IF NOT EXISTS enrollments (
  enrollmentid SERIAL PRIMARY KEY,
  enrollmentdate DATE NOT NULL DEFAULT CURRENT_DATE,
  members_memberid INTEGER NOT NULL,
  classes_classid INTEGER NOT NULL,
  FOREIGN KEY (members_memberid) REFERENCES members(memberid),
  FOREIGN KEY (classes_classid) REFERENCES classes(classid)
);
-- Table: classschedules
CREATE TABLE IF NOT EXISTS classschedules (
  scheduleid SERIAL PRIMARY KEY,
  scheduledate DATE NOT NULL,
  classes_classid INTEGER NOT NULL,
  FOREIGN KEY (classes_classid) REFERENCES classes(classid)
);

-- Trigger : Prevent users younger than 16 years old from registering
CREATE OR REPLACE FUNCTION check_member_age()
RETURNS TRIGGER AS $$
DECLARE
  member_age INT;
BEGIN
  -- Yaşı hesapla
  SELECT EXTRACT(YEAR FROM AGE(TO_DATE(NEW.birthdate, 'YYYY-MM-DD'))) INTO member_age;

  -- Yaş kontrolü
  IF member_age < 16 THEN
    RAISE EXCEPTION 'Üye yaşı 16’den küçük olamaz: % yaşında', member_age;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_member_age
BEFORE INSERT ON members
FOR EACH ROW
EXECUTE FUNCTION check_member_age();


--Trigger: Prevents the deletion of users currently in use in the database
CREATE OR REPLACE FUNCTION protect_member_deletion()
RETURNS TRIGGER AS $$
DECLARE
  related_data_count INT;
BEGIN
  -- İlişkili veri kontrolü
  SELECT COUNT(*) INTO related_data_count
  FROM (
    SELECT members_memberid FROM attendance WHERE members_memberid = OLD.memberid
    UNION ALL
    SELECT members_memberid FROM payments WHERE members_memberid = OLD.memberid
    UNION ALL
    SELECT members_memberid FROM enrollments WHERE members_memberid = OLD.memberid
  ) AS related_data;

  IF related_data_count > 0 THEN
    RAISE EXCEPTION 'This member cannot be deleted: Related records exist.';
  END IF;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER before_delete_member
BEFORE DELETE ON members
FOR EACH ROW
EXECUTE FUNCTION protect_member_deletion();


-- Trigger: Prevent classes to be over limit
CREATE OR REPLACE FUNCTION check_class_participant_limit()
RETURNS TRIGGER AS $$
DECLARE
  participant_count INT;
  max_participants INT;
BEGIN
  SELECT COUNT(*) INTO participant_count
  FROM enrollments
  WHERE classes_classid = NEW.classes_classid;

  SELECT maxparticipants INTO max_participants
  FROM classes
  WHERE classid = NEW.classes_classid;

  IF participant_count >= max_participants THEN
    RAISE EXCEPTION 'Sınıf dolu, yeni katılımcı eklenemez. Maksimum kapasite: %', max_participants;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER before_insert_enrollment
BEFORE INSERT ON enrollments
FOR EACH ROW
EXECUTE FUNCTION check_class_participant_limit();


-- Trigger: Update student count in class for every enrollment
CREATE OR REPLACE FUNCTION update_students_count()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE classes
  SET students_count = students_count + 1
  WHERE classid = NEW.classes_classid;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_insert_enrollment
AFTER INSERT ON enrollments
FOR EACH ROW
EXECUTE FUNCTION update_students_count();


-- Function: Member's payment status check
CREATE OR REPLACE FUNCTION check_member_payment_status(member_id INT)
RETURNS BOOLEAN AS $$
DECLARE
  payment_count INT;
BEGIN
  SELECT COUNT(*) INTO payment_count
  FROM payments
  WHERE members_memberid = member_id
    AND paymentdate > CURRENT_DATE - INTERVAL '30 days'; 

    IF payment_count = 0 THEN
    RETURN FALSE;
  ELSE
    RETURN TRUE;
  END IF;
END;
$$ LANGUAGE plpgsql;


-- Function: Listing the classes the member is registered in
CREATE OR REPLACE FUNCTION list_member_classes(member_id INT)
RETURNS TABLE(class_id INT, class_name VARCHAR, class_date DATE) AS $$
BEGIN
  RETURN QUERY
  SELECT c.classid, c.classname, c.classdate
  FROM classes c
  JOIN enrollments e ON e.classes_classid = c.classid
  WHERE e.members_memberid = member_id;
END;
$$ LANGUAGE plpgsql;


-- Function: Calculating a member's total payments
CREATE OR REPLACE FUNCTION calculate_member_total_payments(member_id INT)
RETURNS NUMERIC(10,2) AS $$
DECLARE
  total_payments NUMERIC(10,2);
BEGIN
  SELECT COALESCE(SUM(amount), 0) INTO total_payments
  FROM payments
  WHERE members_memberid = member_id;

  RETURN total_payments;
END;
$$ LANGUAGE plpgsql;

--Function: Lists classes a specific trainer attends
CREATE OR REPLACE FUNCTION list_trainer_classes(trainer_id INT)
RETURNS TABLE(class_id INT, class_name VARCHAR, class_date DATE, class_time VARCHAR) AS $$
BEGIN
  RETURN QUERY
  SELECT c.classid, c.classname, c.classdate, c.classtime
  FROM classes c
  WHERE c.trainers_trainerid = trainer_id;
END;
$$ LANGUAGE plpgsql;

INSERT INTO membershipplans (planname, price, durationmonths) VALUES 
('Basic', 19.99, 1),
('Standard', 49.99, 3),
('Premium', 89.99, 6);

INSERT INTO members (birthdate, email, firstname, lastname, phonenumber, membershipplans_planid) VALUES 
('1995-06-15', 'john.doe@example.com', 'John', 'Doe', 5551234567, 1),
('1998-03-21', 'jane.smith@example.com', 'Jane', 'Smith', 5559876543, 2),
('2000-12-01', 'sam.wilson@example.com', 'Sam', 'Wilson', 5558765432, 3);

INSERT INTO trainers (firstname, lastname, phonenumber, workinghours, salary, specialization)
VALUES 
('Umut', 'Kurt', 5551346752, '10:00-18:00', 26000, 'Fitness'),
('Alperen', 'Kara', 5553467958, '12:00-20:00', 25800, 'Yoga');

INSERT INTO cleaners (firstname, lastname, phonenumber, workinghours, salary, cleaningarea)
VALUES 
('Yiğit', 'Şeker', 5554478316, '06:00-14:00', 17500, 'Gym Area'),
('Ukbe', 'Tahin', 5556582467, '14:00-22:00', 18000, 'Office-Toilet');

INSERT INTO classes (classdate, classname, classtime, duration, maxparticipants, trainers_trainerid) VALUES 
('2024-12-18', 'Morning Yoga', '08:30', 60, 10, 1),
('2024-12-18', 'Afternoon Pilates', '14:00', 45, 15, 2),
('2024-12-18', 'Evening Cardio', '18:00', 90, 25, 1);

INSERT INTO attendance (attendancedate, members_memberid, classes_classid) VALUES 
('2024-12-18', 1, 1),
('2024-12-18', 2, 2),
('2024-12-18', 3, 3);

INSERT INTO payments (amount, paymentdate, members_memberid) VALUES 
(19.99, '2024-12-01', 1),
(49.99, '2024-12-01', 2),
(89.99, '2024-12-01', 3);

INSERT INTO enrollments (enrollmentdate, members_memberid, classes_classid) VALUES 
('2024-12-10', 1, 1),
('2024-12-10', 2, 1),
('2024-12-10', 3, 3);

INSERT INTO classschedules (scheduledate, classes_classid) VALUES 
('2024-12-18', 1),
('2024-12-18', 2),
('2024-12-18', 3);