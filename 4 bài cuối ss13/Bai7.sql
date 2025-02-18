use ss13;

-- 2
create table banks(
	bank_id int primary key auto_increment,
    bank_name varchar(255) not null,
    status enum('ACTIVE', 'ERROR')
);

-- 3
INSERT INTO banks (bank_id, bank_name, status) VALUES 

(1,'VietinBank', 'ACTIVE'),   

(2,'Sacombank', 'ERROR'),    

(3, 'Agribank', 'ACTIVE');  

-- 4
alter table company_funds
add column bank_id int;

alter table company_funds
add constraint fk_company_funds_bank foreign key (bank_id) references banks(bank_id);

alter table payroll
add column fund_id int;

alter table payroll
add constraint fk_payroll_fund foreign key (fund_id) references company_funds(fund_id);

-- 5
UPDATE company_funds SET bank_id = 1 WHERE balance = 50000.00;

INSERT INTO company_funds (balance, bank_id) VALUES (45000.00,2); 

-- 6
delimiter &&
create trigger CheckBankStatus before insert on payroll
for each row
begin
	declare bank_status char(10);
    
    select status into bank_status
    from banks
    where bank_id = (select bank_id from company_funds where fund_id = NEW.fund_id);
    
    if bank_status = 'ERROR' then
		signal sqlstate '45000'
		set message_text = 'Không thể sử dụng ngân hàng';														
    end if;
end &&
delimiter && 

drop trigger CheckBankStatus;

-- 7
delimiter &&
create procedure TransferSalary(p_emp_id int, p_fund_id int)
begin
	declare isValid int default 0;
    declare v_bank_id int;
    declare v_salary decimal(10,2);
    declare v_company_balance decimal(10,2);
    declare error_message varchar(255);

	start transaction;
    
    select balance, bank_id into v_company_balance, v_bank_id from company_funds
    where fund_id = p_fund_id;
    
    select salary into v_salary from employees where emp_id = p_emp_id;
    
    if(select count(emp_id) from employees where emp_id = p_emp_id) = 0
    or (select count(fund_id) from company_funds where fund_id = p_fund_id) = 0 then
		SET error_message = 'Lỗi: Nhân viên không tồn tại!';
    
		insert into transaction_log(log_message)
        values(error_message);
        set isValid = 1;
        rollback;
	end if;
    
    if v_company_balance < v_salary then
		SET error_message = 'Số dư tài khoản công ty không đủ';
		insert into transaction_log(log_message)
        values(error_message);
        set isValid = 1;
        rollback;
    end if;
    
	insert into payroll(emp_id, salary, pay_date, fund_id)
	values(p_emp_id, v_salary, now(), p_fund_id);
    
    if isValid = 0 then
		update company_funds
        set balance = balance - v_salary
        where bank_id = v_bank_id;
        
        insert into transaction_log(log_message)
        values('Chuyển thành công');
        
        commit;
    end if;
end &&
delimiter && 

call TransferSalary(1, 2);