# Sistema de Gestión de Inventarios

Este proyecto es una API REST para la gestión de inventarios, desarrollada con Node.js, MySQL y MongoDB.

## Requisitos

- Node.js
- MySQL
- MongoDB

## Instalación

1. Clonar el repositorio:
   ```bash
   git clone https://github.com/JoseM-TDS/Proyecto-BDIII
   cd proyecto-BD3/API
   ```

2. Instalar dependencias:
   ```bash
   npm install
   ```

3. Configurar variables de entorno:

   Crea un archivo `.env` en la raíz del proyecto. Puedes usar `.env.example` como guía para conocer las variables necesarias.

4. Iniciar el servidor:
   ```bash
   npm run dev
   ```

## Base de datos

- **MySQL:** Usada para la gestión estructurada de productos y ventas.
- **MongoDB:** Utilizada para registros históricos y trazabilidad del sistema.