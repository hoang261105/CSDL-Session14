-- 1. Bảng departments (Phòng ban)
CREATE TABLE departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(255) NOT NULL
);

-- 2. Bảng employees (Nhân viên)
CREATE TABLE employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    hire_date DATE NOT NULL,
    department_id INT NOT NULL,
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

-- 3. Bảng attendance (Chấm công)
CREATE TABLE attendance (
    attendance_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    check_in_time DATETIME NOT NULL,
    check_out_time DATETIME,
    total_hours DECIMAL(5,2),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- 4. Bảng salaries (Bảng lương)
CREATE TABLE salaries (
    employee_id INT PRIMARY KEY,
    base_salary DECIMAL(10,2) NOT NULL,
    bonus DECIMAL(10,2) DEFAULT 0,
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- 5. Bảng salary_history (Lịch sử lương)
CREATE TABLE salary_history (
    history_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT NOT NULL,
    old_salary DECIMAL(10,2),
    new_salary DECIMAL(10,2),
    change_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- 2
delimiter &&
create trigger pro_before_insert_employee before insert on employees
for each row
begin
	if right(NEW.email, 11) <> '%company.com' then
		set NEW.email = CONCAT(NEW.email, '@company.com');
    end if;
end &&
delimiter &&

drop trigger pro_before_insert_employee;

-- 3
delimiter &&
create trigger pro_after_insert_employee after insert on employees
for each row
begin
	update salaries
    set base_salary = 10000, bonus = 0
    where employee_id = NEW.employee_id;
end &&
delimiter && 

-- 3
delimiter &&
create trigger pro_after_delete_employee after delete on employees
for each row
begin 
	declare salary decimal(10,2);
    
    select base_salary into salary from salaries
    where employee_id = OLD.employee_id;

	insert into salary_history(employee_id, old_salary, new_salary, reason)
    values(OLD.employee_id, salary, 0, 'Employee deleted');
end &&
delimiter &&

-- 4
delimiter &&
create trigger pro_before_update_attendance before update on attendance
for each row
begin
	if NEW.check_out_time is not null then
		set NEW.total_hours =  TIMESTAMPDIFF(HOUR, OLD.check_in_time, NEW.check_out_time) + 
		(TIMESTAMPDIFF(MINUTE, OLD.check_in_time, NEW.check_out_time) % 60) / 60;
    end if;
end &&
delimiter &&

-- 5
INSERT INTO departments (department_name) VALUES 
('Phòng Nhân Sự'),
('Phòng Kỹ Thuật');

INSERT INTO employees (name, email, phone, hire_date, department_id)
VALUES ('Nguyễn Văn A', 'nguyenvana', '0987654321', '2024-02-17', 1);

-- 6
INSERT INTO employees (name, email, phone, hire_date, department_id)
VALUES ('Trần Thị B', 'tranthib@company.com', '0912345678', '2024-02-17', 2);

-- 7
INSERT INTO attendance (employee_id, check_in_time)
VALUES (1, '2024-02-17 08:00:00');

UPDATE attendance
SET check_out_time = '2024-02-17 17:00:00'
WHERE employee_id = 1;   

INSERT INTO salaries (employee_id, base_salary, bonus) VALUES
(1, 50000.00, 0),
(2, 60000.00, 0);


