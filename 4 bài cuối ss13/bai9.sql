-- 2
create table account2s(
	acc_id int primary key auto_increment,
    emp_id int,
    bank_id int,
    foreign key (emp_id) references employees(emp_id),
    foreign key (bank_id) references banks(bank_id),
    amount_added decimal(15,2),
    total_amount decimal(15,2)
);
delete from account2s;

-- 3
INSERT INTO account2s (emp_id, bank_id, amount_added, total_amount) VALUES
(1, 1, 0.00, 12500.00),  
(2, 1, 0.00, 8900.00),   
(3, 1, 0.00, 10200.00),  
(4, 1, 0.00, 15000.00),  
(5, 1, 0.00, 7600.00); 

-- 4
delimiter &&
create procedure TransferSalaryAll()
begin
	declare isFinished bit default 0;
	declare com_balance decimal(15,2);
    declare emp_salary decimal(10,2);
    declare empId int;
    declare accId int;
    declare bankStatus char(10);
    declare idBank int;
    declare idFund int;
	
    declare cursor_employees cursor for
		select e.emp_id, e.salary, a.acc_id
        from employees e
        join account2s a on e.emp_id = a.emp_id;
	
    declare continue handler for NOT FOUND set isFinished = 1;
    declare exit handler for sqlexception
    begin
		rollback;
        insert into transaction_log(log_message, log_time ) 
        values ('FAILED: Transaction error occurred while transferring salary', now());
    end;
    
    select fund_id, balance, bank_id into idFund, com_balance, idBank from company_funds
    where bank_id = (select bank_id from banks limit 1);
    
    if com_balance < (select sum(salary) from employees) then
		insert into transaction_log(log_message, log_time ) 
        values ('FAILED: Company funds insufficient for salary payment', now());
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient company funds!';
    end if;
    
    start transaction;
    open cursor_employees;
	
	cursor_employees: loop
		fetch cursor_employees into empId, emp_salary, accId;
        if isFinished then
			leave cursor_employees;
        end if;
        
        update company_funds
        set balance = balance - emp_salary
        where bank_id = idBank;
        
        insert into payroll(emp_id, salary, pay_date, fund_id)
        values(empId, emp_salary, now(), idFund);
        
        update account2s
        set total_amount = total_amount + emp_salary, amount_added = emp_salary
        where emp_id = empId;
        
    end loop cursor_employees;
    close cursor_employees;
    
    insert into transaction_log(log_message, log_time ) 
	values(CONCAT('SUCCESS: Salaries transferred for ', emp_salary, ' employees'), now());
    
    commit;
end &&
delimiter && 

delete from employees;

call TransferSalaryAll();

-- 6
select * from company_funds;
select * from payroll;
select * from account2s;
select * from transaction_log; 