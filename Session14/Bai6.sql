-- 2
delimiter &&
create trigger before_update_employee_phone
before update on employees
for each row
begin
    -- kiểm tra số điện thoại phải có đúng 10 chữ số
    if char_length(new.phone) <> 10 or new.phone not regexp '^[0-9]+$' then
        signal sqlstate '45000'
        set message_text = 'Số điện thoại phải có đúng 10 chữ số!';
    end if;
end &&
delimiter ;

-- 3
create table notifications (
    notification_id int primary key auto_increment,
    employee_id int not null,
    message text not null,
    created_at timestamp default current_timestamp,
    foreign key (employee_id) references employees(employee_id) on delete cascade
);
 
-- 4
delimiter &&
create trigger after_insert_employee
after insert on employees
for each row
begin
    insert into notifications(employee_id, message)
    values (new.employee_id, 'Chào mừng nhân viên mới!');
end &&
delimiter ;
 
-- 5
delimiter &&
create procedure add_new_employee_with_phone(
    in emp_name varchar(255),
    in emp_email varchar(255),
    in emp_phone varchar(20),
    in emp_hire_date date,
    in emp_department_id int
)
begin
    declare emp_id int;

    start transaction;

    if char_length(emp_phone) <> 10 or emp_phone not regexp '^[0-9]+$' then
        signal sqlstate '45000'
        set message_text = 'số điện thoại không hợp lệ!';
    end if;

    insert into employees (name, email, phone, hire_date, department_id)
    values (emp_name, emp_email, emp_phone, emp_hire_date, emp_department_id);

    set emp_id = last_insert_id();

    commit;
end &&
delimiter &&;
 
call add_new_employee_with_phone('nguyễn văn a', 'a@example.com', '0987654321', '2024-02-19', 1);
