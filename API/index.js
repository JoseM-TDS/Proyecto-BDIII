const express = require("express");
require('dotenv').config();
const mongoose = require("mongoose");
const app = express();
const PORT = process.env.PORT || 3000;
const db = require('./mysql/db');
const Transaction = require('./mongodb/transaction.schema');

app.use(express.json());

mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true
}).then(() => {
  console.log("Conectado a MongoDB");
}).catch((err) => {
  console.error("Error al conectar a MongoDB:", err);
});

app.get("/", (req, res) => {
  res.send("¡Hola mundo!");
});

app.post("/productos", async (req, res) => {
  const { codigo, nombre, descripcion, precioUnitario, stock, ubicacion } = req.body;

  if (!codigo || !nombre || !precioUnitario || stock == null || !ubicacion) {
    return res.status(400).json({ error: "Faltan campos obligatorios." });
  }

  try {
    const [rows] = await db.execute('SELECT * FROM productos WHERE codigo = ?', [codigo]);
    if (rows.length > 0) {
      return res.status(409).json({ error: "El producto ya existe." });
    }

    await db.execute(
      'INSERT INTO productos (codigo, nombre, descripcion, precio_unitario, stock, ubicacion_id) VALUES (?, ?, ?, ?, ?, ?)',
      [codigo, nombre, descripcion, precioUnitario, stock, ubicacion]
    );

    const [productoInsertado] = await db.execute('SELECT id FROM productos WHERE codigo = ?', [codigo]);
    const productoId = productoInsertado[0]?.id;

    await new Transaction({
      tipo: 'registro_producto',
      productoId: productoId?.toString(),
      comentario: `Producto ${nombre} registrado con código ${codigo}.`
    }).save();

    res.status(201).json({ mensaje: "Producto registrado exitosamente." });
  } catch (error) {
    console.error("Error al registrar producto:", error);
    res.status(500).json({ error: "Error interno del servidor." });
  }
});

app.put("/productos/:codigo", async (req, res) => {
  const { nombre, descripcion, precioUnitario, stock, ubicacion } = req.body;
  const codigo = req.params.codigo;

  try {
    const [result] = await db.execute(
      'UPDATE productos SET nombre = ?, descripcion = ?, precio_unitario = ?, stock = ?, ubicacion_id = ? WHERE codigo = ?',
      [nombre, descripcion, precioUnitario, stock, ubicacion, codigo]
    );

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Producto no encontrado." });
    }

    await new Transaction({
      tipo: 'actualizacion_producto',
      productoId: codigo,
      comentario: `Producto con código ${codigo} fue actualizado.`
    }).save();

    res.json({ mensaje: "Producto actualizado exitosamente." });
  } catch (error) {
    console.error("Error al actualizar producto:", error);
    res.status(500).json({ error: "Error interno del servidor." });
  }
});

app.delete("/productos/:codigo", async (req, res) => {
  const codigo = req.params.codigo;

  try {
    const [result] = await db.execute('DELETE FROM productos WHERE codigo = ?', [codigo]);

    if (result.affectedRows === 0) {
      return res.status(404).json({ error: "Producto no encontrado." });
    }

    await new Transaction({
      tipo: 'eliminacion_producto',
      productoId: codigo,
      comentario: `Producto con código ${codigo} fue eliminado.`
    }).save();

    res.json({ mensaje: "Producto eliminado exitosamente." });
  } catch (error) {
    console.error("Error al eliminar producto:", error);
    res.status(500).json({ error: "Error interno del servidor." });
  }
});

app.get("/reportes/inventario", async (req, res) => {
  try {
    const [productos] = await db.execute(`
      SELECT * FROM reporte_inventario_general
    `);
    
    await new Transaction({
      tipo: 'comentario',
      comentario: 'Se generó el reporte de inventario general.'
    }).save();

    res.json(productos);
  } catch (error) {
    console.error("Error al obtener reporte de inventario:", error);
    res.status(500).json({ error: "Error interno del servidor." });
  }
});

app.get("/reportes/por-ubicacion", async (req, res) => {
  try {
    const [productos] = await db.execute(`
      SELECT * FROM reporte_por_ubicacion
    `);
    
    await new Transaction({
      tipo: 'comentario',
      comentario: 'Se generó el reporte de productos por ubicación.'
    }).save();

    res.json(productos);
  } catch (error) {
    console.error("Error al obtener reporte por ubicación:", error);
    res.status(500).json({ error: "Error interno del servidor." });
  }
});

app.get("/reportes/ventas", async (req, res) => {
  try {
    const [ventas] = await db.execute('SELECT * FROM vista_ventas_simuladas');

    await new Transaction({
      tipo: 'comentario',
      comentario: 'Se generó el reporte de ventas simuladas desde la vista MySQL.'
    }).save();

    res.json(ventas);
  } catch (error) {
    console.error("Error al obtener ventas simuladas:", error);
    res.status(500).json({ error: "Error interno del servidor." });
  }
});

app.get("/productos/precio", async (req, res) => {
  const { min, max } = req.query;
  try {
    let query;
    let params;
    
    if (min !== undefined && max !== undefined) {
      query = 'SELECT * FROM productos WHERE precio_unitario BETWEEN ? AND ?';
      params = [min, max];
    } else {
      query = 'SELECT * FROM productos_precio_rango';
      params = [];
    }
    
    const [productos] = await db.execute(query, params);
    
    await new Transaction({
      tipo: 'comentario',
      comentario: `Se consultaron productos por precio. Rango: ${min || 'predeterminado'} - ${max || 'predeterminado'}.`
    }).save();

    res.json(productos);
  } catch (error) {
    console.error("Error al filtrar por precio:", error);
    res.status(500).json({ error: "Error interno del servidor." });
  }
});

app.get("/productos/stock-bajo", async (req, res) => {
  const { limite } = req.query;
  try {
    let query;
    let params;
    
    if (limite) {
      query = 'SELECT * FROM productos WHERE stock < ?';
      params = [limite];
    } else {
      query = 'SELECT * FROM productos_stock_bajo';
      params = [];
    }
    
    const [productos] = await db.execute(query, params);
    
    await new Transaction({
      tipo: 'comentario',
      comentario: `Se consultaron productos con stock bajo. Límite: ${limite || 'predeterminado'}.`
    }).save();

    res.json(productos);
  } catch (error) {
    console.error("Error al obtener productos con stock bajo:", error);
    res.status(500).json({ error: "Error interno del servidor." });
  }
});

app.get("/productos/ubicacion/:ubicacionId", async (req, res) => {
  const { ubicacionId } = req.params;
  try {
    const [productos] = await db.execute(
      'SELECT * FROM reporte_por_ubicacion WHERE almacen = (SELECT nombre FROM ubicaciones WHERE id = ?)',
      [ubicacionId]
    );

    await new Transaction({
      tipo: 'comentario',
      productoId: ubicacionId,
      comentario: `Se consultaron productos en la ubicación ${ubicacionId}.`
    }).save();

    res.json(productos);
  } catch (error) {
    console.error("Error al filtrar por ubicación:", error);
    res.status(500).json({ error: "Error interno del servidor." });
  }
});

app.post("/ventas", async (req, res) => {
  const { codigo, cantidad } = req.body;

  if (!codigo || !cantidad) {
    return res.status(400).json({ error: "Código y cantidad son requeridos." });
  }

  try {
    await db.execute('CALL registrar_venta(?, ?)', [codigo, cantidad]);

    await new Transaction({
      tipo: 'venta',
      productoId: codigo,
      comentario: `Venta simulada de ${cantidad} unidades del producto con código ${codigo}.`
    }).save();

    res.status(200).json({ mensaje: "Venta registrada exitosamente." });
  } catch (error) {
    console.error("Error al registrar venta:", error);
    res.status(500).json({ error: "Error interno del servidor." });
  }
});

app.listen(PORT, () => {
  console.log(`Servidor corriendo en http://localhost:${PORT}`);
});
