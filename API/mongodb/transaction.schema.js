const mongoose = require('mongoose');

const transactionSchema = new mongoose.Schema({
  tipo: {
    type: String,
    required: true,
    enum: ['registro_producto', 'actualizacion_producto', 'eliminacion_producto', 'venta', 'comentario']
  },
  productoId: {
    type: String
  },
  comentario: {
    type: String
  },
  fecha: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('transactions', transactionSchema);