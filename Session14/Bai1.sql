CREATE DATABASE ss14;
USE ss14;

-- 1. Bảng customers (Khách hàng)
CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Bảng orders (Đơn hàng)
CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_amount DECIMAL(10,2) DEFAULT 0,
    status ENUM('Pending', 'Completed', 'Cancelled') DEFAULT 'Pending',
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- 3. Bảng products (Sản phẩm)
CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(255) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Bảng order_items (Chi tiết đơn hàng)
CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 5. Bảng inventory (Kho hàng)
CREATE TABLE inventory (
    product_id INT PRIMARY KEY,
    stock_quantity INT NOT NULL CHECK (stock_quantity >= 0),
    last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 6. Bảng payments (Thanh toán)
CREATE TABLE payments (
    payment_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    payment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    amount DECIMAL(10,2) NOT NULL,
    payment_method ENUM('Credit Card', 'PayPal', 'Bank Transfer', 'Cash') NOT NULL,
    status ENUM('Pending', 'Completed', 'Failed') DEFAULT 'Pending',
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

INSERT INTO customers (name, email, phone, address) VALUES
('Nguyễn Văn A', 'nguyenvana@company.com', '0909123456', '123 Đường Lê Lợi, TP.HCM'),
('Trần Thị B', 'tranthib@company.com', '0912233445', '456 Đường Nguyễn Huệ, Hà Nội'),
('Lê Văn C', 'levanc@company.com', '0922334455', '789 Đường Trần Hưng Đạo, Đà Nẵng');

INSERT INTO products (name, price, description) VALUES
('Laptop Dell XPS 13', 25000000, 'Laptop cao cấp của Dell, màn hình 13 inch, chip Intel Core i7'),
('iPhone 14 Pro Max', 32000000, 'Điện thoại Apple cao cấp, màn hình 6.7 inch, chip A16 Bionic'),
('Tai nghe Sony WH-1000XM5', 7000000, 'Tai nghe chống ồn tốt nhất của Sony, âm thanh chất lượng cao');

INSERT INTO inventory (product_id, stock_quantity) VALUES
(1, 50), -- Laptop Dell XPS 13 có 50 cái trong kho
(2, 30), -- iPhone 14 Pro Max có 30 cái trong kho
(3, 100); -- Tai nghe Sony WH-1000XM5 có 100 cái trong kho

INSERT INTO orders (customer_id, total_amount, status) VALUES
(1, 57000000, 'Pending'), -- Đơn hàng của Nguyễn Văn A
(2, 32000000, 'Completed'), -- Đơn hàng của Trần Thị B
(3, 7000000, 'Cancelled'); -- Đơn hàng của Lê Văn C


-- 2
delimiter &&
create trigger pro_before_insert before insert on order_items
for each row
begin 
	declare stock_available int;

	select stock_quantity into stock_available from inventory
    where product_id = NEW.product_id;
    
    if stock_available < NEW.quantity then
		signal sqlstate '45000'
        set message_text = 'Không đủ hàng trong kho!';
    end if;
end &&
delimiter && 

-- 3
delimiter &&
create trigger pro_after_insert after insert on order_items
for each row
begin
	update orders
    set total_amount = total_amount + NEW.price * NEW.quantity
    where order_id = NEW.order_id;
end &&
delimiter && 

-- 4
delimiter &&
create trigger pro_before_update before update on order_items
for each row
begin
	declare stock_available int;
    
    select quantity into stock_available
    from products
    where product_id = NEW.product_id;

	if NEW.quantity > stock_available then
		signal sqlstate '45000'
        set message_text = 'Không đủ hàng trong kho để cập nhật số lượng!';
    end if;
end &&
delimiter && 

-- 5
delimiter &&
create trigger pro_after_update after update on order_items
for each row
begin
	update orders
    set total_amount = total_amount - (OLD.price * OLD.quantity) + (NEW.price * NEW.quantity)
    where order_id = NEW.order_id;
end &&
delimiter && 

-- 6
delimiter &&
create trigger pro_before_delete before delete on orders
for each row
begin
	declare orderStatus char(10);
    
    select status into orderStatus from orders
    where order_id = OLD.order_id;
    
    if orderStatus = 'Completed' then
		signal sqlstate '45000'
        set message_text = 'Không thể xóa đơn hàng đã thanh toán!';
    end if;
end &&
delimiter && 

-- 7
delimiter &&
create trigger pro_after_delete after delete on inventory
for each row
begin
	update inventory
    set stock_quantity = stock_quantity + OLD.stock_quantity
    where product_id = OLD.product_id;
end &&
delimiter && 

-- 8
drop trigger pro_before_insert;
drop trigger pro_after_insert;
drop trigger pro_before_update;
drop trigger pro_after_update;
drop trigger pro_before_delete;
drop trigger pro_after_delete; 