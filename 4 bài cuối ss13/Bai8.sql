use ss13;

-- 2
create table student_status(
	student_id int primary key,
    foreign key (student_id) references students(student_id),
    status enum('ACTIVE', 'GRADUATED', 'SUSPENDED')
);

-- 3
INSERT INTO student_status (student_id, status) VALUES

(1, 'ACTIVE'), -- Nguyễn Văn An có thể đăng ký

(2, 'GRADUATED'); -- Trần Thị Ba đã tốt nghiệp, không thể đăng ký 

-- 4
delimiter &&
create procedure pro_registerCourse(p_studentName varchar(50), p_courseName varchar(100))
begin
    declare idStudent int;
    declare idCourse int;
    declare studentStatus char(10);
    
    start transaction;
    
    select course_id into idCourse from courses 
    where course_name = p_courseName;
    
    select student_id into idStudent from students
    where student_name = p_studentName;

    select status into studentStatus from student_status 
    where student_id = idStudent;
    
    if idStudent is null or idCourse is null then
        insert into enrollments_history(student_id, course_id, action)
        values (idStudent, idCourse, 'FAILED: Student or course does not exist');
        commit;
        rollback;
    else
        if studentStatus in ('GRADUATED', 'SUSPENDED') then
            insert into enrollments_history(student_id, course_id, action)
            values(idStudent, idCourse, 'FAILED: Student not eligible');
            commit;
            rollback;
        else
            if (select count(*) from enrollments where student_id = idStudent and course_id = idCourse) > 0 then
                insert into enrollments_history(student_id, course_id, action)
                values(idStudent, idCourse, 'FAILED: Already enrolled');
                commit;
                rollback;
            else
                if (select available_seats from courses where course_id = idCourse) > 0 then
                    insert into enrollments(student_id, course_id)
                    values(idStudent, idCourse);
                    
                    update courses
                    set available_seats = available_seats - 1
                    where course_id = idCourse;
                    
                    insert into enrollments_history(student_id, course_id, action)
                    values(idStudent, idCourse, 'Registered');
                    
                    commit;
                else    
                    insert into enrollments_history(student_id, course_id, action)
                    values(idStudent, idCourse, 'FAILED: No available seats');
                    commit;
                    rollback;
                end if;
            end if;
        end if;
    end if;
end &&
delimiter ;

call pro_registerCourse('Trần Thị Ba', 'Lập trình C');

select * from enrollments_history;