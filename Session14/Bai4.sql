-- 2
delimiter &&
create procedure IncreaseSalary(empId int, newSalary decimal(10,2), reason text)
begin
    declare oldSalary decimal(10,2);
    
    start transaction;

    select base_salary into oldSalary from salaries
    where employee_id = empId;
    
    if oldSalary is null then
		rollback;
        signal sqlstate '45000'
        set message_text = 'Nhân viên không tồn tại!';
	else
		insert into salary_history(employee_id, old_salary, new_salary, reason)
        values(empId, oldSalary, newSalary, reason);
        
        update salaries
        set base_salary = newSalary
        where employee_id = empId;
        
        commit;
    end if;
end &&
delimiter && 

CALL IncreaseSalary(1, 5000.00, 'Tăng lương định kỳ');
-- 3
delimiter &&
create procedure DeleteEmployee(empId int)
begin
	start transaction;
    
    if(select count(employee_id) from employees where employee_id = empId) = 0 then
		rollback;
        signal sqlstate '45000'
        set message_text = 'Nhân viên không tồn tại!';
	else
		delete from employees
        where employee_id = empId;
        
        delete from salaries
        where employee_id = empId;
        
        commit;
    end if;
end &&
delimiter && 

call deleteEmployee(2);