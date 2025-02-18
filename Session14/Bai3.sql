-- 2
delimiter &&
create procedure sp_create_order(
	customerId int,
    productId int,
    quantity int,
    price decimal(10,2)
)
begin
	declare stock_available int;
    declare orderId int;
	start transaction;
    
    select stock_quantity into stock_available 
    from inventory
    where product_id = productId;
    
    if stock_available < quantity then
		rollback;
        signal sqlstate '45000'
        set message_text = 'Không đủ hàng trong kho!';
	else
		insert into orders(customer_id, order_date, total_amount, status)
        values(customerId, now(), (price * quantity), 'Pending');
        
        set orderId = last_insert_id();
        
        insert into order_items(order_id, product_id, quantity, price)
        values(orderId, productId, quantity, price);
        
        update inventory
        set stock_quantity = stock_quantity - quantity
        where product_id = productId;
        
        commit;
    end if;
end &&
delimiter && 

call sp_create_order(1, 2, 2, 320000);

-- 3
delimiter &&
create procedure sp_payment_order(orderId int, payment_method varchar(20))
begin
	declare orderStatus char(10);
    declare totalMoney decimal(10,2);
	start transaction;
    
    select total_amount, status into totalMoney, orderStatus
    from orders
    where order_id = orderId;
    
    if orderStatus <> 'Pending' then
		rollback;
        signal sqlstate '45000'
        set message_text = 'Chỉ có thể thanh toán đơn hàng ở trạng thái Pending!';
	else
		insert into payments(order_id, payment_date, amount, payment_method, status)
        values(orderId, now(), totalMoney, payment_method, 'Completed');
        
        update orders
        set status = 'Completed'
        where order_id = orderId;
        
        commit;
    end if;
end &&
delimiter && 

call sp_payment_order(9, 'Credit Card');

-- 4
delimiter &&
create procedure sp_cancel_order(orderId int)
begin
	declare orderStatus char(10);
    start transaction;
    
    select status into orderStatus
    from orders
    where order_id = orderId;
    
  
	update inventory i
	join order_items oi on oi.product_id = i.product_id
	set stock_quantity = stock_quantity + oi.quantity
	where order_id = orderId;
        
	delete from order_items where order_id = orderId;
        
	update orders
	set status = 'Cancelled'
	where order_id = orderId;
	commit;
end &&
delimiter &&   

call sp_cancel_order(9);

-- 5
drop procedure sp_create_order;
drop procedure sp_payment_order;
drop procedure sp_cancel_order; 