# Base de Datos Relacional (MySQL)
## Diseño de la base de datos

### Diagramas de Entidad-Relación
![Diagrama ER](/Diagrama_ER_SQL.png)

### Tablas
1. **Nombre:** store_location (Almacén)  
**Status:** Activo  
**Dueño:** Christian Mendez  
**Columnas:**

| No. | Llave | Nombre | Tipo de dato |       Descripción           |
|:---:|:-----:|--------|:------------:|-----------------------------|
|  1  |  PK   |   id   |      int     | Identificador de un almacén |
|  2  |       |  name  | varchar(255) |    Nombre de un almacén     |

---

2. **Nombre:** product (Producto)  
**Status:** Activo  
**Dueño:** Christian Mendez  
**Columnas:**

| No. | Llave |     Nombre    | Tipo de dato |              Descripción               |
|:---:|:-----:|---------------|:------------:|----------------------------------------|
|  1  |  PK   |      id       |      int     |     Identificador de un producto       |
|  2  |       |      code     |      int     |   Código del producto en el sistema    |
|  3  |       |      name     | varchar(255) |          Nombre del producto           |
|  4  |       |  description  |     text     |        Descripción del producto        |
|  5  |       |  unit_price   | decimal(7,2) |            Precio unitario             |
|  6  |       |     stock     |      int     |   Cantidad de unidades disponibles     |
|  7  |  FK   | store_location|      int     | Almacén en el que se encuentra ubicado |

---

### Partición vertical
3. **Nombre:** product_stock (Stock de productos)  
**Status:** Activo  
**Dueño** Jose Meléndez  
**Columnas:**

| No. | Llave |     Nombre    | Tipo de dato |              Descripción               |
|:---:|:-----:|---------------|:------------:|----------------------------------------|
|  1  |  PK   |      id       |      int     |     Identificador de un producto       |
|  2  |       |      code     |      int     |   Código del producto en el sistema    |
|  3  |       |     stock     |      int     |   Cantidad de unidades disponibles     |
|  4  |       | store_location|      int     | Almacén en el que se encuentra ubicado |
|  5  |  FK   |      id       |      int     |     Identificador de un producto       |

---

4. **Nombre:** sale (Venta)  
   **Status:** Activo  
   **Dueño:** Jose Melendez  
   **Columnas:**

| No. | Llave |    Nombre    | Tipo de dato |         Descripción           |
|:---:|:-----:|--------------|:------------:|-------------------------------|
|  1  |  PK   |      id      |      int     |  Identificador de una venta   |
|  2  |       | unit_amount  |      int     |      Cantidad de unidades     |
|  3  |       |    date      |      date    |        Fecha de la venta      |
|  4  |       |  total_value | decimal(7,2) |    Valor total de la venta    |
|  5  |  FK   |  product_id  |      int     | El producto que se ha vendido |

---

### Partición horizontal
5. **Nombre:** sale_byYearDate (Ventas por año)  
**Status:** Activo  
**Dueño** Jose Meléndez  
**Columnas:**

| No. | Llave |    Nombre    | Tipo de dato |         Descripción           |
|:---:|:-----:|--------------|:------------:|-------------------------------|
|  1  |  PK   |      id      |      int     |  Identificador de una venta   |
|  2  |       | unit_amount  |      int     |      Cantidad de unidades     |
|  3  |       |    date      |      date    |        Fecha de la venta      |
|  4  |       |  total_value | decimal(7,2) |    Valor total de la venta    |
|  5  |  FK   |  product_id  |      int     | El producto que se ha vendido |

### Función de partición
```sql
CREATE PARTITION FUNCTION PartitionByYear (DATE) AS RANGE LEFT FOR VALUES ('2022-12-31', '2023-12-31', '2024-12-31');
```

### Esquema de partición:
**Partición por año:** 2022, 2023, 2024, 2025  
**Ubicación de archivos de datos:** 'C:\ParticionesDB\InventarioDB'

```sql
CREATE PARTITION SCHEME SchemePartitionByYear AS PARTITION SchemePartitionByYear
TO (FG_2022, FG_2023, FG_2024, FG_2025);
```

---

6. **Nombre:** auditoria (Auditoria de usuarios)  
**Status:** Activo  
**Dueño** Byron Monzón  
**Columnas:**

| No. | Llave |     Nombre     | Tipo de dato |           Descripción             |
|:---:|:-----:|----------------|:------------:|-----------------------------------|
|  1  |  PK   |       id       |      int     |  Identificador de una auditoria   |
|  2  |       |     usuario    |  varchar(50) |       Usuario a utilizar          |
|  2  |       |     accion     |  varchar(10) |        Accion a realizar          |
|  3  |       |     tabla      |  varchar(50) |        Tabla a modificar          |
|  4  |       |     fecha      |  timestamp   |      Fecha en que se realiza      |
|  5  |       | datos_antiguos |     Text     | Datos antiguos dentro de la tabla |
|  6  |       |  datos_nuevos  |     Text     |  Datos nuevos dentro de la tabla  |

---

## Gestión de inventario
### Usuarios
1. **Admin:** admin_galileo  
**Privilegios:** All Privileges

2. **Operador:** operador_galileo  
**Privilegios:** select, insert, update, delete, alter, execute

### Procedimientos y funciones
1. **Registrar producto:** registrar_producto  
    Ingresa el registro de un nuevo producto a la tabla "product".

2. **Actualizar producto:** actualizar_producto  
    Actualiza los datos de un producto registrado dentro de la base de datos.

3. **Eliminar producto:** eliminar_producto  
    Eliminar el registro de un producto a partir de su código en el sistema.

4. **Actualizacion de stock:** actualizar_stock_venta  
    Actualizar la cantidad de unidades disponibles de un producto posterior a su venta.

5. **Reposición de inventario:** reposicionar_stock  
   Actualizar la cantidad de unidades disponibles de un producto al ingresar nuevos unidades de un proveedor.

6. **Consultar stock disponible:** consultar_stock_producto  
   Consultar la cantidad de unidades disponibles según el código del producto en el sistema.

### Triggers
1. **Auditoria:** Crear un nuevo registro de auditoria de un usuario, después de realizar una modificiación de una tabla:  
* after_insert_producto
* after_update_producto
* after_delete_producto

### Vistas
1. **Ventas mensuales:** vista_ventas_mensuales  
    Vista que muestra ventas agrupadas por mes y producto.

2. **Inventario por ubicación:** vista_inventario_por_ubicacion  
    Vista que muestra los productos de un inventario por ubicación de almacén.

3. **Inventario total:** vista_inventario_general  
    Vista general del inventario con el valor total del stock de productos.

4. **Productos por ubicación:** vista_productos_por_ubicacion  
    Vista de los productos disponibles por ubicación de almaceén.

5. **Ventas de producto:** vista_ventas_por_producto  
    Vista de las ventas realizadas por producto.

6. **Ventas por año:** vista_ventas_por_año  
    Vista de las ventas realizadas por año.

7. **Ventas por almacén:** vista_ventas_por_almacen  
    Vista de productos vendidos desde un almacén en específico.

8. **Ventas por mes:** vista_ventas_por_producto_mes  
    Vista de productos vendidos dentro de un mes específico.

### Consultas
* Consulta los productos con mayor valor total disponible en inventario.
```sql
SELECT 
    p.name AS Producto,
    p.stock AS Stock_Actual,
    p.unit_price AS Precio_Unitario,
    (p.stock * p.unit_price) AS Valor_Total_En_Inventario
FROM product p
ORDER BY Valor_Total_En_Inventario DESC
LIMIT 5;
```

* Consulta los productos disponibles agrupados por almacén.
```sql
SELECT 
    s.name AS Almacen, 
    p.code AS Codigo, 
    p.name AS Producto, 
    p.stock AS Stock
FROM product p
JOIN store_location s ON p.store_location = s.id
ORDER BY s.name;
```

* Consulta la cantidad de productos con stock bajo menor a 5 unidades.
```sql
SELECT 
    p.name AS Producto,
    p.stock AS Stock_Actual,
    p.unit_price AS Precio_Unitario
FROM product p
WHERE p.stock <= 5  -- Ajusta el valor de stock bajo según sea necesario
ORDER BY p.stock;
```

* Consulta los productos cuyo valor unitario es mayor a una cantidad específica.
```sql
SELECT 
    p.code AS Codigo, 
    p.name AS Producto, 
    p.unit_price AS Precio_Unitario
FROM 
    product p
WHERE 
    p.unit_price > 100;
```

* Consulta la información específica de un producto según su código.
```sql
SELECT 
    p.code AS Codigo, 
    p.name AS Producto, 
    p.description AS Descripcion, 
    p.unit_price AS Precio_Unitario, 
    p.stock AS Stock_Actual
FROM 
    product p
WHERE 
    p.code = 12345;
```

* Consulta que muestra las ventas realizadas según la fecha de la venta.
```sql
SELECT 
    p.name AS Producto, 
    s.cantidad AS Cantidad_Vendida, 
    s.fecha AS Fecha_Venta, 
    s.precio_total AS Valor_Total
FROM sales s
JOIN product p ON s.id_producto = p.id
ORDER BY s.fecha DESC;
```

* Consulta la cantidad total de stock disponible y su valor total en el inventario.
```sql
SELECT 
    SUM(p.stock) AS Total_Stock, 
    SUM(p.stock * p.unit_price) AS Valor_Total
FROM 
    product p;
```

* Consulta que obtiene la cantidad de stock disponible por ubicación de almacén.
```sql
SELECT 
    s.name AS Ubicacion, 
    SUM(p.stock) AS Total_Stock
FROM 
    product p
JOIN 
    store_location s ON p.store_location = s.id
GROUP BY 
    s.name;
```

* Consulta un rango de productos según su precio unitario.
```sql
SELECT 
    p.code AS Codigo, 
    p.name AS Producto, 
    p.unit_price AS Precio_Unitario
FROM 
    product p
WHERE 
    p.unit_price BETWEEN 10 AND 50;
```

* Consulta un rango de productos según su precio unitario en una ubicación de almacén específica.
```sql
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
    s.name = 'Ubicación A';
```

* Consulta de productos con stock bajo según el rango de su precio unitario.
```sql
SELECT 
    code AS Codigo,
    name AS Producto,
    stock AS Stock_Actual,
    unit_price AS Precio_Unitario
FROM product
WHERE stock < 10
  AND unit_price BETWEEN 50 AND 150;
```

* Consulta de total vendido y los ingresos totales de ventas de un producto dentro de un mes y año específico.
```sql
SELECT 
    p.name AS Producto,
    SUM(s.unit_amount) AS Total_Vendido,
    SUM(s.total_value) AS Total_Ingresos
FROM sale s
JOIN product p ON s.product_id = p.id
WHERE MONTH(s.date) = 1 AND YEAR(s.date) = 2024  -- Puedes modificar el mes y año
GROUP BY p.name
ORDER BY Total_Vendido DESC;
```

* Consulta de la cantidad de ventas por ubicación de almacén y producto seleccionado
```sql
SELECT 
    s.name AS Almacen,
    p.name AS Producto,
    SUM(sa.unit_amount) AS Cantidad_Vendida
FROM sale_byYearDate sa
JOIN product p ON sa.product_id = p.id
JOIN store_location s ON p.store_location = s.id
GROUP BY s.name, p.name
ORDER BY s.name, Cantidad_Vendida DESC;
```

* Consulta de ventas totales de un producto en un año específico
```sql
SELECT 
    p.name AS Producto,
    SUM(sa.total_value) AS Total_Ventas
FROM sale_byYearDate sa
JOIN product p ON sa.product_id = p.id
WHERE YEAR(sa.date) = 2024  -- Puedes modificar el año
GROUP BY p.name
ORDER BY Total_Ventas DESC;
```

* Consulta de la cantidad de ventas mensuales de un producto específico.
```sql
SELECT 
    DATE_FORMAT(s.date, '%Y-%m') AS Mes,
    SUM(s.unit_amount) AS Total_Vendido,
    SUM(s.total_value) AS Ingresos
FROM sale s
WHERE s.product_id = 1  -- Cambia el ID del producto según sea necesario
GROUP BY Mes
ORDER BY Mes DESC;
```

* Consulta que muestra el total de unidades vendidas y el total de ventas por semana de cada año.
```sql
SELECT 
    YEAR(s.date) AS Año,
    WEEK(s.date) AS Semana,
    SUM(s.unit_amount) AS Total_Unidades_Vendidas,
    SUM(s.total_value) AS Total_Ventas
FROM sale s
GROUP BY Año, Semana
ORDER BY Año DESC, Semana DESC;
```

* Consulta de ventas semanales por producto específico
```sql
SELECT 
    p.name AS Producto,
    AVG(s.unit_amount) AS Promedio_Vendido_Semanal
FROM sale s
JOIN product p ON s.product_id = p.id
GROUP BY p.name
ORDER BY Promedio_Vendido_Semanal DESC;
```

* Consulta de las ventas de productos en los últimos siete días 
```sql
SELECT 
    p.name AS Producto,
    SUM(s.unit_amount) AS Total_Vendido,
    SUM(s.total_value) AS Total_Ventas
FROM sale s
JOIN product p ON s.product_id = p.id
WHERE s.date BETWEEN CURDATE() - INTERVAL 7 DAY AND CURDATE()
GROUP BY p.name
ORDER BY Total_Vendido DESC;
```