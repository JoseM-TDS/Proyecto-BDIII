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
TO (FG_2022, FG_2023, FG_2024, FG_2025, FG_2026);

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