-- Crear base de datos
CREATE DATABASE IF NOT EXISTS inventario_db;
USE inventario_db;

-- Tabla de roles
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

-- Tabla de usuarios
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario VARCHAR(50) NOT NULL UNIQUE,
    contrasena VARCHAR(255) NOT NULL,
    rol_id INT NOT NULL,
    FOREIGN KEY (rol_id) REFERENCES roles(id)
);

-- Tabla de ubicaciones (almacenes)
CREATE TABLE ubicaciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    direccion VARCHAR(255)
);

-- Tabla de productos
CREATE TABLE productos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(20) NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    descripcion TEXT,
    precio_unitario DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0,
    ubicacion_id INT NOT NULL,
    fecha_creacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (ubicacion_id) REFERENCES ubicaciones(id)
);

-- Trigger: evitar duplicados por nombre y ubicación
DELIMITER $$
CREATE TRIGGER evitar_duplicado_producto
BEFORE INSERT ON productos
FOR EACH ROW
BEGIN
  IF EXISTS (
    SELECT 1 FROM productos 
    WHERE nombre = NEW.nombre AND ubicacion_id = NEW.ubicacion_id
  ) THEN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Producto duplicado en la misma ubicación';
  END IF;
END;
$$
DELIMITER ;

-- Vista: Reporte inventario general
CREATE VIEW reporte_inventario_general AS
SELECT
    codigo,
    nombre,
    stock,
    precio_unitario,
    (stock * precio_unitario) AS valor_total
FROM productos;

-- Vista: Reporte productos por ubicación
CREATE VIEW reporte_por_ubicacion AS
SELECT
    u.nombre AS almacen,
    p.codigo,
    p.nombre,
    p.stock
FROM productos p
JOIN ubicaciones u ON p.ubicacion_id = u.id
ORDER BY u.nombre;

-- Vista: Reporte de productos con stock bajo (menor a 15)
CREATE VIEW productos_stock_bajo AS
SELECT
    codigo,
    nombre,
    stock
FROM productos
WHERE stock < 15;

-- Vista: Filtro por rango de precios
CREATE VIEW productos_precio_rango AS
SELECT
    codigo,
    nombre,
    precio_unitario
FROM productos
WHERE precio_unitario BETWEEN 100 AND 1000;

-- Insertar datos de ejemplo
INSERT INTO roles (nombre) VALUES ('administrador'), ('operador');

INSERT INTO usuarios (nombre_usuario, contrasena, rol_id) VALUES
('admin', 'admin123', 1),
('operador1', 'op123', 2);

INSERT INTO ubicaciones (nombre, direccion) VALUES
('Almacén Central', 'Zona 1'),
('Sucursal Norte', 'Zona 17');

INSERT INTO productos (codigo, nombre, descripcion, precio_unitario, stock, ubicacion_id) VALUES
('P001', 'Mouse Óptico', 'Mouse con cable USB', 75.50, 100, 1),
('P002', 'Teclado Mecánico', 'RGB con switches azules', 350.00, 50, 1),
('P003', 'Monitor 24 pulgadas', 'Full HD, HDMI', 1200.00, 20, 2),
('P004', 'Laptop 15"', 'Intel i5, 8GB RAM', 5500.00, 10, 2);

DELIMITER $$
CREATE PROCEDURE registrar_venta(IN p_codigo VARCHAR(20), IN p_cantidad INT)
BEGIN
  DECLARE v_stock INT;

  SELECT stock INTO v_stock FROM productos WHERE codigo = p_codigo;

  IF v_stock IS NULL THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Producto no encontrado.';
  ELSEIF v_stock < p_cantidad THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stock insuficiente para la venta.';
  ELSE
    UPDATE productos SET stock = stock - p_cantidad WHERE codigo = p_codigo;

    INSERT INTO ventas (producto_id, cantidad)
    SELECT id, p_cantidad FROM productos WHERE codigo = p_codigo;
  END IF;
END$$
DELIMITER ;

-- Tabla de ventas simuladas
CREATE TABLE ventas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    producto_id INT NOT NULL,
    cantidad INT NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (producto_id) REFERENCES productos(id)
);

-- Vista: Reporte de ventas simuladas
CREATE VIEW vista_ventas_simuladas AS
SELECT
    p.codigo,
    p.nombre,
    v.cantidad,
    v.fecha,
    (v.cantidad * p.precio_unitario) AS total
FROM ventas v
JOIN productos p ON v.producto_id = p.id;