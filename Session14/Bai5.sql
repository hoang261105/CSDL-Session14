-- 2
delimiter &&
create trigger before_insert_check_payment
before insert on payments
for each row
begin
    declare order_total decimal(10,2);

    select total_amount into order_total
    from orders
    where order_id = new.order_id;

    if new.amount <> order_total then
        signal sqlstate '45000'
        set message_text = 'Số tiền thanh toán không khớp với tổng đơn hàng!';
    end if;
end &&
delimiter ;


-- 3
 -- Tạo bảng lưu log thay đổi trạng thái đơn hàng

CREATE TABLE order_logs (

    log_id INT PRIMARY KEY AUTO_INCREMENT,

    order_id INT NOT NULL,

    old_status ENUM('Pending', 'Completed', 'Cancelled'),

    new_status ENUM('Pending', 'Completed', 'Cancelled'),

    log_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (order_id) REFERENCES orders(order_id)

); 

-- 4
delimiter &&
create trigger after_update_order_status
after update on orders
for each row
begin
    if old.status <> new.status then
        insert into order_logs (order_id, old_status, new_status, changed_at)
        values (new.order_id, old.status, new.status, now());
    end if;
end &&
delimiter &&;

-- 5
delimiter &&
create procedure sp_update_order_status_with_payment(
    in order_id int,
    in new_status varchar(20),
    in payment_method varchar(20)
)
begin
    declare order_status varchar(20);
    declare total_money decimal(10,2);
    
    start transaction;

    select status, total_amount into order_status, total_money
	from orders
	where order_id = order_id
	limit 1
	for update; -- khóa hàng để tránh thay đổi đồng thời

    if order_status = new_status then
        rollback;
        signal sqlstate '45000'
        set message_text = 'Đơn hàng đã có trạng thái này!';
    end if;

    if new_status = 'Completed' then
        insert into payments(order_id, payment_date, amount, payment_method, status)
        values (order_id, now(), total_money, payment_method, 'Completed');
    end if;

    update orders
    set status = new_status
    where order_id = order_id;
    
    commit;
end &&
delimiter ;

call sp_update_order_status_with_payment(8, 'Pending', 'Bank');

-- 6
drop trigger before_insert_check_payment;
drop trigger after_update_order_status;
drop procedure sp_update_order_status_with_payment;
 