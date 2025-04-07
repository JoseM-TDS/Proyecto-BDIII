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

## Gestión de inventario
## Implementación de Funciones
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

### Usuarios
1. **Admin:** admin_galileo  
**Privilegios:** All Privileges

2. **Operador:** operador_galileo  
**Privilegios:** select, insert, update, delete, alter

### Consultas
* Consulta el valor total de cada producto disponible.
```sql
SELECT 
    p.code AS Codigo, 
    p.name AS Producto, 
    p.stock AS Stock_Actual, 
    p.unit_price AS Precio_Unitario, 
    (p.stock * p.unit_price) AS Valor_Total
FROM product p;
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

* Consulta la cantidad de productos con stock bajo menor a 10 unidades.
```sql
SELECT 
    code AS Codigo, 
    name AS Producto, 
    stock AS Stock
FROM product
WHERE stock < 10;
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
