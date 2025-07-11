TRUNCATE TABLE 
  PagoDeVenta,
  ProductoEnVenta,
  Compra,
  ProductoEnCompra,
  Venta,
  ProductoEnSucursal,
  JoyeroAlmacenaCategoria,
  Joya,
  Perfume,
  Joyero,
  Producto,
  Cliente,
  Sucursal,
  Proveedor,
  Categoria
RESTART IDENTITY CASCADE;

-- Categorías
INSERT INTO Categoria (nombre, descripcion) VALUES
  ('Collares', 'Joyas para el cuello'),
  ('Pulseras', 'Joyas para la muñeca'),
  ('Aromas', 'Fragancias y perfumes');

-- Proveedores
INSERT INTO Proveedor (rut, correo, nombre) VALUES
  (50094121, 'prov1@joyas.cl',    'Brillantes S.A.'),
  (50401221, 'fragancias@perfume.cl', 'AromaPlus Ltda.');

-- Sucursales
INSERT INTO Sucursal (calle, numero_casa, comuna) VALUES
  ('Av. Siempre Viva', 742, 'Springfield'),
  ('Calle Falsa',      123, 'Shelbyville');

-- Clientes
INSERT INTO Cliente
  (rut, telefono, calle, numero_casa, comuna, correo, nombre)
VALUES
  (14980301, 912345678, 'Main St',  111, 'Concepción',   'juan.perez@mail.cl', 'Juan Pérez'),
  (16831227, 923456789, '2nd Ave',  222, 'Chiguayante',  'ana.soto@mail.cl',  'Ana Soto');

  -- Productos generales
INSERT INTO Producto
  (nombre, descripcion, precio_actual, imagen, tipo_producto)
VALUES
  ('Collar Diamante', 'Collar de diamantes finos', 50000, NULL, 'Joya'),
  ('Pulsera Oro',     'Pulsera de oro amarillo',    30000, NULL, 'Joya'),
  ('Perfume Lavanda', 'Fragancia de lavanda suave',15000, NULL, 'Perfume'),
  ('Joyero Madera',   'Joyero artesanal de madera',12000, NULL, 'Joyero');

-- Joya
INSERT INTO Joya (id_producto, peso, material, categoria) VALUES
  (1, 12.50, 'Oro blanco',    1),
  (2,  8.25, 'Oro amarillo',  2);

-- Perfume
INSERT INTO Perfume (id_producto, fragancia, marca, mililitros) VALUES
  (3, 'Lavanda', 'AromaPlus', 100);

-- Joyero
INSERT INTO Joyero (id_producto, ancho, alto, largo) VALUES
  (4, 20.0, 10.0, 15.0);

-- Relación joyero–categoría
INSERT INTO JoyeroAlmacenaCategoria (id_categoria, id_joyero, cantidad) VALUES
  (1, 4, 10),
  (2, 4,  5);

-- Compras
INSERT INTO Compra (fecha, id_proveedor, id_sucursal) VALUES
  (CURRENT_DATE, 50094121, 1),
  (CURRENT_DATE, 50401221, 2);

-- Detalle de compra (genera stock en ProductoEnSucursal)
INSERT INTO ProductoEnCompra
  (id_compra, id_producto, cantidad, precio_total)
VALUES
  -- para sucursal 1: productos 1, 2 y 3
  (1, 1,  5, 250000),
  (1, 2,  3,  90000),
  (1, 3,  4,  60000),

  -- para sucursal 2: producto 4
  (2, 4,  2,  24000);

  -- 6.1 Venta (estado por defecto “Pendiente”)
INSERT INTO Venta (fecha, estado, id_cliente, id_sucursal)
VALUES
  (CURRENT_DATE, DEFAULT, 14980301, 1),
  (CURRENT_DATE, DEFAULT, 16831227, 1);

-- 6.2 Detalle de la venta (verifica y descuenta stock)
INSERT INTO ProductoEnVenta
  (id_producto, id_venta, cantidad, precio_en_venta)
VALUES
  (1, 1, 2, 50000),
  (3, 1, 1, 15000),
  (1, 2, 1, 50000);

-- 6.3 Pago de la venta (actualiza estado a “Parcial” o “Pagada”)
INSERT INTO PagoDeVenta (id_venta, monto, fecha)
VALUES
  (1, 115000, CURRENT_DATE);

