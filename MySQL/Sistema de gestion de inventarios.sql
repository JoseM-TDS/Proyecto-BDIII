CREATE DATABASE inventario_db;
CREATE TABLE `store_location` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `name` varchar(255) NOT NULL
);

CREATE TABLE `product` (
  `id` int PRIMARY KEY AUTO_INCREMENT,
  `code` int UNIQUE,
  `name` varchar(255) NOT NULL,
  `description` text,
  `unit_price` decimal(7,2),
  `stock` int NOT NULL DEFAULT 0,
  `store_location` int NOT NULL
);

ALTER TABLE `product` ADD FOREIGN KEY (`store_location`) REFERENCES `store_location` (`id`);

-- Particion vertical 'product'
CREATE TABLE `product_stock` (
    `id` int PRIMARY KEY AUTO_INCREMENT,
    `code` int UNIQUE,
    `stock` int NOT NULL DEFAULT 0,
    `store_location` int NOT NULL
);

ALTER TABLE `product_stock` ADD FOREIGN KEY (`id`) REFERENCES `product` (`id`);

CREATE TABLE `sale` (
    `id` int PRIMARY KEY AUTO_INCREMENT,
    `unit_amount` int NOT NULL,
    `date` date NOT NULL,
    `total_value` decimal(7,2),
    `product_id` int NOT NULL
);

ALTER TABLE `sale` ADD FOREIGN KEY (`product_id`) REFERENCES `product` (`id`);

-- Particion Horizontal 'sale'
-- Function Partition
CREATE PARTITION FUNCTION PartitionByYear (DATE) AS RANGE LEFT FOR VALUES ('2022-12-31', '2023-12-31', '2024-12-31');

-- Filegroups
ALTER DATABASE inventario_db ADD FILEGROUP FG_2022;
ALTER DATABASE inventario_db ADD FILEGROUP FG_2023;
ALTER DATABASE inventario_db ADD FILEGROUP FG_2024;
ALTER DATABASE inventario_db ADD FILEGROUP FG_2025;

-- Data Files
ALTER DATABASE inventario_db ADD FILE (
    NAME = P_2022,
    FILENAME = 'C:\ParticionesDB\InventarioDB\P_2022.ndf'
) TO FILEGROUP FG_2022;

ALTER DATABASE inventario_db ADD FILE (
    NAME = P_2023,
    FILENAME = 'C:\ParticionesDB\InventarioDB\P_2023.ndf'
) TO FILEGROUP FG_2023;

ALTER DATABASE inventario_db ADD FILE (
    NAME = P_2024,
    FILENAME = 'C:\ParticionesDB\InventarioDB\P_2024.ndf'
) TO FILEGROUP FG_2024;

ALTER DATABASE inventario_db ADD FILE (
    NAME = P_2025,
    FILENAME = 'C:\ParticionesDB\InventarioDB\P_2025.ndf'
) TO FILEGROUP FG_2025;

-- Partition Scheme
CREATE PARTITION SCHEME SchemePartitionByYear AS PARTITION SchemePartitionByYear
TO (FG_2022, FG_2023, FG_2024, FG_2025);

-- Tabla con particion horizontal
CREATE TABLE sale_byYearDate (
    `id` int PRIMARY KEY AUTO_INCREMENT,
    `unit_amount` int NOT NULL,
    `date` date NOT NULL,
    `total_value` decimal(7,2),
    `product_id` int NOT NULL
) ON SchemePartitionByYear (date);

-- REGISTRAR
DELIMITER //
CREATE PROCEDURE registrar_producto(
    IN p_code INT, 
    IN p_name VARCHAR(255), 
    IN p_description TEXT, 
    IN p_unit_price DECIMAL(7,2), 
    IN p_stock INT, 
    IN p_store_location INT
)

BEGIN
    INSERT INTO product (code, name, description, unit_price, stock, store_location)
    VALUES (p_code, p_name, p_description, p_unit_price, p_stock, p_store_location);
END //

-- ACTUALIZAR
CREATE PROCEDURE actualizar_producto(
    IN p_code INT, 
    IN p_new_name VARCHAR(255), 
    IN p_new_description TEXT, 
    IN p_new_unit_price DECIMAL(7,2), 
    IN p_new_stock INT, 
    IN p_new_store_location INT
)
BEGIN
    UPDATE product
    SET name = p_new_name,
        description = p_new_description,
        unit_price = p_new_unit_price,
        stock = p_new_stock,
        store_location = p_new_store_location
    WHERE code = p_code;
END //

-- ELIMINAR
CREATE PROCEDURE eliminar_producto(
    IN p_code INT
)
BEGIN
    DELETE FROM product WHERE code = p_code;
END //
DELIMITER ;

-- GESTION DE INVENTARIO
-- Actualizar el stock
DELIMITER //
CREATE PROCEDURE actualizar_stock_venta(IN producto_code INT, IN cantidad_vendida INT)
BEGIN
    UPDATE product
    SET stock = stock - cantidad_vendida
    WHERE code = producto_code AND stock >= cantidad_vendida;
END //
DELIMITER ;

-- Consultar el stock disponible
DELIMITER //
CREATE FUNCTION consultar_stock_producto(producto_code INT)
RETURNS INT
DETERMINISTIC
BEGIN
    DECLARE stock INT;
    SELECT stock INTO stock
    FROM product
    WHERE code = producto_code;
    RETURN stock;
END //
DELIMITER ;

-- Reposicion de inventario
DELIMITER //
CREATE PROCEDURE reposicionar_stock(IN producto_code INT, IN cantidad_reposicion INT)
BEGIN
    UPDATE product
    SET stock = stock + cantidad_reposicion
    WHERE code = producto_code;
END //
DELIMITER ;

-- Crear usuario admin
CREATE USER 'admin'@'localhost' IDENTIFIED BY 'admin_galileo';

-- Crear usuario operador
CREATE USER 'operador'@'localhost' IDENTIFIED BY 'operador_galileo';

-- Asignar todos los privilegios al usuario admin
GRANT ALL PRIVILEGES ON inventario_db.* TO 'admin'@'localhost';

-- Permisos para el usuario operador 
GRANT select, insert, update, delete, alter on inventario_db.* to 'operador'@'localhost';

-- Aplicar los privilegios
FLUSH PRIVILEGES;

-- Ver los privilegios de un usuario
SHOW GRANTS FOR 'admin'@'localhost';
SHOW GRANTS FOR 'operador'@'localhost';

-- GESTION SEGURA DE USUARIOS

-- Permitir que el operador ejecute los procedimientos necesarios
GRANT EXECUTE ON PROCEDURE inventario_db.registrar_producto TO 'operador'@'localhost';
GRANT EXECUTE ON PROCEDURE inventario_db.actualizar_producto TO 'operador'@'localhost';
GRANT EXECUTE ON PROCEDURE inventario_db.eliminar_producto TO 'operador'@'localhost';
GRANT EXECUTE ON PROCEDURE inventario_db.actualizar_stock_venta TO 'operador'@'localhost';
GRANT EXECUTE ON PROCEDURE inventario_db.reposicionar_stock TO 'operador'@'localhost';

-- Permitir que el operador ejecute la función de consulta de stock de productos
GRANT EXECUTE ON FUNCTION inventario_db.consultar_stock_producto TO 'operador'@'localhost';

-- Auditoria de usuarios
CREATE TABLE auditoria (
  id INT AUTO_INCREMENT PRIMARY KEY,
  usuario VARCHAR(50),
  accion VARCHAR(10),
  tabla VARCHAR(50),
  fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  datos_antiguos TEXT,
  datos_nuevos TEXT
);

DELIMITER //
CREATE TRIGGER after_insert_producto
AFTER INSERT ON product
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (usuario, accion, tabla, datos_nuevos)
  VALUES (CURRENT_USER(), 'INSERT', 'product', CONCAT('ID: ', NEW.id, ', Code: ', NEW.code, ', Name: ', NEW.name));
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER after_update_producto
AFTER UPDATE ON product
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (usuario, accion, tabla, datos_antiguos, datos_nuevos)
  VALUES (CURRENT_USER(), 'UPDATE', 'product', 
          CONCAT('ID: ', OLD.id, ', Code: ', OLD.code, ', Name: ', OLD.name, ', Price: ', OLD.unit_price, ', Stock: ', OLD.stock),
          CONCAT('ID: ', NEW.id, ', Code: ', NEW.code, ', Name: ', NEW.name, ', Price: ', NEW.unit_price, ', Stock: ', NEW.stock));
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER after_delete_producto
AFTER DELETE ON product
FOR EACH ROW
BEGIN
  INSERT INTO auditoria (usuario, accion, tabla, datos_antiguos)
  VALUES (CURRENT_USER(), 'DELETE', 'product', CONCAT('ID: ', OLD.id, ', Code: ', OLD.code, ', Name: ', OLD.name));
END //
DELIMITER ;

SELECT * FROM auditoria;

-- CONSULTAS BASICAS DE REPORTES GENERALES

-- Consulta que muestra el código, nombre, stock actual, precio unitario y el valor total de cada producto.
SELECT 
    p.code AS Codigo, 
    p.name AS Producto, 
    p.stock AS Stock_Actual, 
    p.unit_price AS Precio_Unitario, 
    (p.stock * p.unit_price) AS Valor_Total
FROM product p;

-- Consulta que muestra los productos agrupados por almacén, mostrando el nombre del almacén, código, nombre del producto y su stock.

SELECT 
    s.name AS Almacen, 
    p.code AS Codigo, 
    p.name AS Producto, 
    p.stock AS Stock
FROM product p
JOIN store_location s ON p.store_location = s.id
ORDER BY s.name;

-- Consulta que obtiene los productos con stock bajo (menor a 10 unidades). 

SELECT 
    code AS Codigo, 
    name AS Producto, 
    stock AS Stock
FROM product
WHERE stock < 10; -- Se puede ajustar el valor según sea necesario.

-- Consulta que muestra los productos cuyo precio unitario es mayor a un valor específico (en este caso, 100).

SELECT 
    p.code AS Codigo, 
    p.name AS Producto, 
    p.unit_price AS Precio_Unitario
FROM 
    product p
WHERE 
    p.unit_price > 100;  -- Reemplaza 100 con el valor deseado
    
    -- Consulta que obtiene la información de un producto específico según su código.
    
SELECT 
    p.code AS Codigo, 
    p.name AS Producto, 
    p.description AS Descripcion, 
    p.unit_price AS Precio_Unitario, 
    p.stock AS Stock_Actual
FROM 
    product p
WHERE 
    p.code = 12345;  -- Reemplaza 12345 por el código del producto que deseas consultar
    
    -- Consulta que muestra las ventas realizadas, incluyendo el nombre del producto, la cantidad vendida, la fecha de la venta y el valor total de la transacción.

SELECT 
    p.name AS Producto, 
    s.unit_amount AS Cantidad_Vendida, 
    s.date AS Fecha_Venta, 
    s.total_value AS Valor_Total
FROM sale s
JOIN product p ON s.product_id = p.id
ORDER BY s.date DESC;

-- Consulta que obtiene el total del stock disponible en la base de datos y su valor total en inventario.

SELECT 
    SUM(p.stock) AS Total_Stock, 
    SUM(p.stock * p.unit_price) AS Valor_Total
FROM 
    product p;

-- Consulta que obtiene el total de stock por ubicación de almacén.

SELECT 
    s.name AS Ubicacion, 
    SUM(p.stock) AS Total_Stock
FROM 
    product p
JOIN 
    store_location s ON p.store_location = s.id
GROUP BY 
    s.name;
    
    -- Consulta que muestra los productos cuyo precio unitario está dentro de un rango determinado.

SELECT 
    p.code AS Codigo, 
    p.name AS Producto, 
    p.unit_price AS Precio_Unitario
FROM 
    product p
WHERE 
    p.unit_price BETWEEN 10 AND 50;  -- Reemplaza 10 y 50 con el rango de precios que necesitas
    
    
    -- Consulta similar a la primera, pero muestra la información de los productos que pertenecen a una ubicación específica.

    SELECT 
    p.code AS Codigo, 
    p.name AS Producto, 
    p.stock AS Stock_Actual, 
    p.unit_price AS Precio_Unitario
FROM 
    product p
JOIN 
    store_location s ON p.store_location = s.id
WHERE 
    s.name = 'Ubicación A';  -- Reemplaza 'Ubicación A' por la ubicación deseada

-- Crear tabla de ventas por año y fecha
CREATE TABLE sale_byYearDate (
    id INT PRIMARY KEY AUTO_INCREMENT,
    unit_amount INT NOT NULL,
    date DATE NOT NULL,
    total_value DECIMAL(7,2),
    product_id INT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES product(id)
);

-- Insertar datos en la tabla sale_byYearDate
INSERT INTO sale_byYearDate (unit_amount, date, total_value, product_id) VALUES
(5, '2024-03-15', 3750.00, 1), -- Laptop HP
(10, '2024-03-16', 250.00, 2), -- Mouse Logitech
(8, '2024-03-17', 440.00, 3),  -- Teclado Redragon
(3, '2024-03-18', 390.00, 4),  -- Monitor Samsung
(6, '2024-03-19', 480.00, 5);  -- Disco SSD Kingston

-- Crear tabla de ubicaciones de almacén
CREATE TABLE IF NOT EXISTS store_location (
  id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(255) NOT NULL
);

-- Crear tabla de productos
CREATE TABLE IF NOT EXISTS product (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code INT UNIQUE,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  unit_price DECIMAL(7,2),
  stock INT NOT NULL DEFAULT 0,
  store_location INT NOT NULL,
  FOREIGN KEY (store_location) REFERENCES store_location(id)
);

-- Crear tabla de ventas
CREATE TABLE IF NOT EXISTS sale (
  id INT AUTO_INCREMENT PRIMARY KEY,
  unit_amount INT NOT NULL,
  date DATE NOT NULL,
  total_value DECIMAL(7,2),
  product_id INT NOT NULL,
  FOREIGN KEY (product_id) REFERENCES product(id)
);

-- Insertar ubicaciones de almacenes
INSERT INTO store_location (name) VALUES 
('Almacén Central'), 
('Sucursal Norte'), 
('Sucursal Sur');

-- Insertar productos
INSERT INTO product (code, name, description, unit_price, stock, store_location) VALUES
(1001, 'Laptop HP', 'Laptop HP 15 pulgadas', 750.00, 25, 1),
(1002, 'Mouse Logitech', 'Mouse inalámbrico', 25.00, 100, 1),
(1003, 'Teclado Redragon', 'Teclado mecánico RGB', 55.00, 40, 2),
(1004, 'Monitor Samsung', 'Monitor LED 24"', 130.00, 15, 3),
(1005, 'Disco SSD Kingston', 'SSD 500GB', 80.00, 30, 2);

-- Insertar ventas
INSERT INTO sale (unit_amount, date, total_value, product_id) VALUES
(2, '2024-01-15', 1500.00, 1),  -- Laptop HP
(5, '2024-01-16', 125.00, 2),   -- Mouse Logitech
(3, '2024-02-01', 165.00, 3),   -- Teclado
(1, '2024-03-10', 130.00, 4),   -- Monitor
(4, '2024-03-12', 320.00, 5),   -- SSD
(7, '2024-04-05', 175.00, 2);   -- Mouse Logitech

-- ======================================
-- VISTAS PARA REPORTES
-- ======================================

-- Vista que muestra ventas agrupadas por mes y producto
CREATE VIEW vista_ventas_mensuales AS
SELECT 
    p.name AS producto,
    DATE_FORMAT(s.date, '%Y-%m') AS mes,
    SUM(s.unit_amount) AS total_vendido,
    SUM(s.total_value) AS ingresos
FROM sale s
JOIN product p ON s.product_id = p.id
GROUP BY p.name, mes
ORDER BY mes DESC;

-- Vista que muestra inventario por ubicación
CREATE VIEW vista_inventario_por_ubicacion AS
SELECT 
    s.name AS almacen,
    COUNT(p.id) AS total_productos,
    SUM(p.stock) AS stock_total,
    SUM(p.unit_price * p.stock) AS valor_total
FROM product p
JOIN store_location s ON p.store_location = s.id
GROUP BY s.name;

-- Vista general del inventario con valor total
CREATE VIEW vista_inventario_general AS
SELECT 
    p.code AS Codigo,
    p.name AS Producto,
    p.stock AS Stock_Actual,
    p.unit_price AS Precio_Unitario,
    (p.stock * p.unit_price) AS Valor_Total
FROM product p;

-- Vista de productos por ubicación
CREATE VIEW vista_productos_por_ubicacion AS
SELECT 
    s.name AS Almacen,
    p.code AS Codigo,
    p.name AS Producto,
    p.stock AS Stock
FROM product p
JOIN store_location s ON p.store_location = s.id
ORDER BY s.name;

-- Vista de ventas por producto
CREATE VIEW vista_ventas_por_producto AS
SELECT 
    p.name AS Producto,
    SUM(s.unit_amount) AS Total_Unidades_Vendidas,
    SUM(s.total_value) AS Total_Valor_Ventas
FROM sale_byYearDate s
JOIN product p ON s.product_id = p.id
GROUP BY p.name;

-- Vista de ventas por año
CREATE VIEW vista_ventas_por_año AS
SELECT 
    YEAR(date) AS Anio,
    COUNT(*) AS Total_Ventas,
    SUM(unit_amount) AS Total_Unidades_Vendidas,
    SUM(total_value) AS Total_Ingresos
FROM sale_byYearDate
GROUP BY YEAR(date)
ORDER BY Anio DESC;

-- Vista del valor total de inventario por ubicación
CREATE VIEW vista_valor_inventario_por_ubicacion AS
SELECT 
    s.name AS Ubicacion,
    COUNT(p.id) AS Total_Productos,
    SUM(p.stock) AS Stock_Total,
    SUM(p.unit_price * p.stock) AS Valor_Total
FROM product p
JOIN store_location s ON p.store_location = s.id
GROUP BY s.name;

-- Procedimiento para reporte de ventas en un rango de fechas para un almacén específico
DELIMITER $$

CREATE PROCEDURE reporte_ventas_rango_fecha(
    IN fecha_inicio DATE, 
    IN fecha_fin DATE, 
    IN ubicacion_nombre VARCHAR(255)
)
BEGIN
    SELECT  
        s.name AS Almacen,
        p.name AS Producto,
        sa.unit_amount AS Cantidad_Vendida,
        sa.date AS Fecha_Venta,
        sa.total_value AS Valor_Total
    FROM sale_byYearDate sa
    JOIN product p ON sa.product_id = p.id
    JOIN store_location s ON p.store_location = s.id
    WHERE sa.date BETWEEN fecha_inicio AND fecha_fin
      AND s.name = ubicacion_nombre
    ORDER BY sa.date DESC;
END$$

DELIMITER ;

-- Vista de ventas por año
CREATE VIEW vista_ventas_por_anio AS
SELECT  
    s.name AS Almacen,
    p.name AS Producto,
    sa.unit_amount AS Cantidad_Vendida,
    sa.date AS Fecha_Venta,
    sa.total_value AS Valor_Total,
    YEAR(sa.date) AS Año
FROM sale_byYearDate sa
JOIN product p ON sa.product_id = p.id
JOIN store_location s ON p.store_location = s.id;

SELECT * FROM vista_ventas_por_anio LIMIT 0, 1000;

-- Vista de inventario por ubicación
CREATE OR REPLACE VIEW vista_inventario_por_ubicacion AS
SELECT 
    s.name AS almacen,
    COUNT(p.id) AS total_productos,
    SUM(p.stock) AS stock_total,
    SUM(p.unit_price * p.stock) AS valor_total
FROM product p
JOIN store_location s ON p.store_location = s.id
GROUP BY s.name;

-- Productos vendidos desde un almacén específico
SELECT 
    s.name AS Almacen,
    p.name AS Producto,
    sa.unit_amount AS Cantidad_Vendida,
    sa.date AS Fecha_Venta,
    sa.total_value AS Valor_Total
FROM sale_byYearDate sa
JOIN product p ON sa.product_id = p.id
JOIN store_location s ON p.store_location = s.id
WHERE s.name = 'Almacén Central';

-- Vistas de ventas
-- Ventas por Producto en un Mes Específico
CREATE VIEW ventas_por_producto_mes AS
SELECT 
    p.name AS Producto,
    SUM(s.unit_amount) AS Total_Vendido,
    SUM(s.total_value) AS Total_Ingresos
FROM sale s
JOIN product p ON s.product_id = p.id
WHERE MONTH(s.date) = 1 AND YEAR(s.date) = 2024  -- Puedes modificar el mes y año
GROUP BY p.name
ORDER BY Total_Vendido DESC;

-- Ventas por Almacén y Producto
CREATE VIEW ventas_por_almacen_producto AS
SELECT 
    s.name AS Almacen,
    p.name AS Producto,
    SUM(sa.unit_amount) AS Cantidad_Vendida
FROM sale_byYearDate sa
JOIN product p ON sa.product_id = p.id
JOIN store_location s ON p.store_location = s.id
GROUP BY s.name, p.name;

-- ======================================
-- CONSULTAS AVANZADAS
-- ======================================
-- Consulta avanzada 1: Ventas por Producto en un Mes Específico
-- Muestra el total vendido y los ingresos generados por cada producto en un mes y año específicos.
SELECT 
    p.name AS Producto,
    SUM(s.unit_amount) AS Total_Vendido,
    SUM(s.total_value) AS Total_Ingresos
FROM sale s
JOIN product p ON s.product_id = p.id
WHERE MONTH(s.date) = 1 AND YEAR(s.date) = 2024  -- Puedes modificar el mes y año
GROUP BY p.name
ORDER BY Total_Vendido DESC;

-- Consulta avanzada 2: Ventas por Almacén y Producto
-- Muestra las cantidades vendidas de cada producto por cada almacén.
SELECT 
    s.name AS Almacen,
    p.name AS Producto,
    SUM(sa.unit_amount) AS Cantidad_Vendida
FROM sale_byYearDate sa
JOIN product p ON sa.product_id = p.id
JOIN store_location s ON p.store_location = s.id
GROUP BY s.name, p.name
ORDER BY s.name, Cantidad_Vendida DESC;

-- Consulta avanzada 3: Ventas Totales por Producto en un Año
-- Calcula las ventas totales de cada producto en un año específico.
SELECT 
    p.name AS Producto,
    SUM(sa.total_value) AS Total_Ventas
FROM sale_byYearDate sa
JOIN product p ON sa.product_id = p.id
WHERE YEAR(sa.date) = 2024  -- Puedes modificar el año
GROUP BY p.name
ORDER BY Total_Ventas DESC;

-- Consulta avanzada 4: Productos con Bajo Stock
-- Muestra los productos cuyo stock actual es igual o menor a 5 unidades.
SELECT 
    p.name AS Producto,
    p.stock AS Stock_Actual,
    p.unit_price AS Precio_Unitario
FROM product p
WHERE p.stock <= 5  -- Ajusta el valor de stock bajo según sea necesario
ORDER BY p.stock;

-- Consulta avanzada 5: Ventas de un Producto Específico por Mes
-- Muestra las ventas mensuales de un producto específico. Puedes ajustar el ID del producto.
SELECT 
    DATE_FORMAT(s.date, '%Y-%m') AS Mes,
    SUM(s.unit_amount) AS Total_Vendido,
    SUM(s.total_value) AS Ingresos
FROM sale s
WHERE s.product_id = 1  -- Cambia el ID del producto según sea necesario
GROUP BY Mes
ORDER BY Mes DESC;

-- Consulta avanzada 6: Productos con Mayor Valor Total en Inventario
-- Muestra los productos con mayor valor total en inventario (stock * precio unitario).
SELECT 
    p.name AS Producto,
    p.stock AS Stock_Actual,
    p.unit_price AS Precio_Unitario,
    (p.stock * p.unit_price) AS Valor_Total_En_Inventario
FROM product p
ORDER BY Valor_Total_En_Inventario DESC
LIMIT 5;

-- Consulta avanzada 7: Ventas Semanales por Año
-- Muestra el total de unidades vendidas y el total de ventas por semana de cada año.
SELECT 
    YEAR(s.date) AS Año,
    WEEK(s.date) AS Semana,
    SUM(s.unit_amount) AS Total_Unidades_Vendidas,
    SUM(s.total_value) AS Total_Ventas
FROM sale s
GROUP BY Año, Semana
ORDER BY Año DESC, Semana DESC;

-- Consulta avanzada 8: Promedio de Ventas Semanal por Producto
-- Calcula el promedio de unidades vendidas semanalmente por producto.
SELECT 
    p.name AS Producto,
    AVG(s.unit_amount) AS Promedio_Vendido_Semanal
FROM sale s
JOIN product p ON s.product_id = p.id
GROUP BY p.name
ORDER BY Promedio_Vendido_Semanal DESC;

-- Consulta avanzada 9: Ventas en los Últimos 7 Días
-- Muestra las ventas de los productos en los últimos 7 días.
SELECT 
    p.name AS Producto,
    SUM(s.unit_amount) AS Total_Vendido,
    SUM(s.total_value) AS Total_Ventas
FROM sale s
JOIN product p ON s.product_id = p.id
WHERE s.date BETWEEN CURDATE() - INTERVAL 7 DAY AND CURDATE()
GROUP BY p.name
ORDER BY Total_Vendido DESC;


-- Consultas avanzada 10
-- Productos con stock bajo y precio dentro de un rango
SELECT 
    code AS Codigo,
    name AS Producto,
    stock AS Stock_Actual,
    unit_price AS Precio_Unitario
FROM product
WHERE stock < 10
  AND unit_price BETWEEN 50 AND 150;
