CREATE TABLE course_fees (
    course_id INT PRIMARY KEY,
    fee DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (course_id) REFERENCES courses(course_id)
);

CREATE TABLE student_wallets (
    student_id INT PRIMARY KEY,
    balance DECIMAL(10,2) NOT NULL DEFAULT 0,
    FOREIGN KEY (student_id) REFERENCES students(student_id) 
);

INSERT INTO course_fees (course_id, fee) VALUES
(1, 100.00), -- Lập trình C: 100$
(2, 150.00); -- Cơ sở dữ liệu: 150$

INSERT INTO student_wallets (student_id, balance) VALUES
(1, 200.00), -- Nguyễn Văn An có 200$
(2, 50.00);  -- Trần Thị Ba chỉ có 50$

-- 4
delimiter &&
create procedure pro_transferFee(p_studentName varchar(50), p_courseName varchar(100))
begin
	declare idStudent int;
    declare idCourse int;
    declare availableSeat int;
    declare stu_balance decimal(10,2);
    declare course_fee decimal(10,2);
    
    select student_id into idStudent from students
    where student_name = p_studentName;
    
    select course_id into idCourse from courses
    where course_name = p_courseName;
    
    if idStudent is null or idCourse is null then
		insert into enrollments_history(student_id, course_id, action)
        values (idStudent, idCourse, 'FAILED: Student or course does not exist');
        commit;
        rollback;
	else 
		if(select count(*) from enrollments where student_id = idStudent and course_id = idCourse) then
			insert into enrollments_history(student_id, course_id, action)
			values(idStudent, idCourse, 'FAILED: Already enrolled');
			commit;
			rollback;
		else 
			select available_seats into availableSeat from courses
            where course_id = idCourse;
            
            if availableSeat < 0 then
				insert into enrollments_history(student_id, course_id, action)
				values(idStudent, idCourse, 'FAILED: No available seats');
				commit;
				rollback;
			else
				select balance into stu_balance from student_wallets
                where student_id = idStudent;
                
                select fee into course_fee from course_fees
                where course_id = idCourse;
                
                if stu_balance < course_fee then
					insert into enrollments_history(student_id, course_id, action)
					values(idStudent, idCourse, 'FAILED: Insufficient balance');
					commit;
					rollback;
				else	
					insert into enrollments(student_id, course_id)
                    values(idStudent, idCourse);
                    
                    update student_wallets
                    set balance = balance - course_fee
                    where student_id = idStudent;
                    
                    update courses
                    set available_seats = available_seats - 1
                    where course_id = idCourse;
                    
                    insert into enrollments_history(student_id, course_id, action)
					values(idStudent, idCourse, 'Registered');
                    
                    commit;
                end if;
            end if;
        end if;
    end if;
end &&
delimiter && 

call pro_transferFee('Nguyễn Văn An', 'Lập trình C');
select * from enrollments_history;
select * from enrollments;
select * from student_wallets;