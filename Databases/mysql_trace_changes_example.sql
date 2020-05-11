/*
just a stupid didactic example where INSERT/UPDATE operations on a table are
logged in another table (= poor man's auditing system LOL!)
*/

CREATE TABLE person (name VARCHAR(20), age TINYINT(4), sex CHAR(1));
CREATE TABLE changes (date TIMESTAMP, tb VARCHAR(255), action VARCHAR(255), msg VARCHAR(255));

DELIMITER $$
CREATE PROCEDURE save_change_person(p1 VARCHAR(255), p2 TINYINT(4), p3 CHAR(1), act VARCHAR(255))
BEGIN DECLARE msg CHAR(255);
    SET msg = CONCAT('Changes: ', p1, ',', p2, ',', p3); 
    INSERT INTO changes VALUES (NOW(), 'person', act, msg);
END $$;

CREATE TRIGGER t_save_change_person_insert AFTER INSERT ON person FOR EACH ROW CALL save_change_person(NEW.name, NEW.age, NEW.sex, 'INSERT');
CREATE TRIGGER t_save_change_person_update AFTER UPDATE ON person FOR EACH ROW CALL save_change_person(NEW.name, NEW.age, NEW.sex, 'UPDATE');
