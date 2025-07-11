CREATE TABLE Producto (
    id_producto SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    descripcion VARCHAR(200),
    precio_actual INTEGER CHECK (precio_actual >= 0),
    imagen BYTEA,
    tipo_producto VARCHAR(10) NOT NULL 
);

CREATE TABLE Categoria (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(50),
    descripcion VARCHAR(200)
);

CREATE TABLE Joya (
    id_producto INTEGER PRIMARY KEY,
    peso NUMERIC(8,2) CHECK (peso>0),
    material VARCHAR(90),
    categoria INTEGER NOT NULL,
    FOREIGN KEY (categoria) REFERENCES Categoria(id_categoria),
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto)
);

CREATE TABLE Perfume (
    id_producto INTEGER PRIMARY KEY,
    fragancia VARCHAR(60),
    marca VARCHAR(50),
    mililitros INTEGER CHECK (mililitros>0),
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto)
);

CREATE TABLE Joyero (
    id_producto INTEGER PRIMARY KEY,
    ancho NUMERIC(4,1) CHECK (ancho>0),
    alto NUMERIC(4,1) CHECK (alto>0),  
    largo NUMERIC(4,1) CHECK (largo>0),
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto)
);

CREATE TABLE JoyeroAlmacenaCategoria (
    id_categoria INTEGER,
    id_joyero INTEGER,
    cantidad INTEGER CHECK (cantidad>0),
    PRIMARY KEY (id_categoria,id_joyero)
);

CREATE TABLE Proveedor (
    rut INTEGER PRIMARY KEY,
    correo VARCHAR(320),
    nombre VARCHAR(60)
);

CREATE TABLE Sucursal (
    id_sucursal SERIAL PRIMARY KEY,
    calle VARCHAR(50),
    numero_casa INTEGER,
    comuna VARCHAR(40)
);

CREATE TABLE Compra (
    id_compra SERIAL PRIMARY KEY,
    fecha DATE,
    id_proveedor INTEGER,
    id_sucursal INTEGER,
    FOREIGN KEY (id_proveedor) REFERENCES Proveedor(rut) ON UPDATE CASCADE,
    FOREIGN KEY (id_sucursal) REFERENCES Sucursal(id_sucursal) ON UPDATE CASCADE
);

CREATE TABLE ProductoEnCompra (
    id_compra INTEGER,
    id_producto INTEGER,
    cantidad INTEGER CHECK (cantidad>0),
    precio_total INTEGER,
    PRIMARY KEY (id_compra,id_producto),
    FOREIGN KEY (id_compra) REFERENCES Compra(id_compra) ON UPDATE CASCADE,
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto) ON UPDATE CASCADE
);



CREATE TABLE ProductoEnSucursal(
    id_producto INTEGER,
    id_sucursal INTEGER,
    stock INTEGER CHECK (stock >=0),
    PRIMARY KEY (id_producto,id_sucursal),
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto),
    FOREIGN KEY (id_sucursal) REFERENCES Sucursal(id_sucursal)
);

CREATE TABLE Cliente (
    rut INTEGER PRIMARY KEY,
    telefono INTEGER,
    calle VARCHAR(50),
    numero_casa INTEGER,
    comuna VARCHAR(40),
    correo VARCHAR(320),
    nombre VARCHAR(60)
);

CREATE TABLE Venta (
    id_venta SERIAL PRIMARY KEY,
    fecha DATE,
    estado VARCHAR(15) DEFAULT 'Pendiente',
    id_cliente INTEGER NOT NULL,
    id_sucursal INTEGER NOT NULL,
    FOREIGN KEY (id_cliente) REFERENCES Cliente(rut) ON UPDATE CASCADE,
    FOREIGN KEY (id_sucursal) REFERENCES Sucursal(id_sucursal) ON UPDATE CASCADE
);

CREATE TABLE PagoDeVenta (
    id_pago SERIAL PRIMARY KEY,
    id_venta INTEGER,
    monto INTEGER CHECK (monto >0),
    fecha DATE,
    FOREIGN KEY (id_venta) REFERENCES Venta(id_venta)
);

CREATE TABLE ProductoEnVenta (
    id_producto INTEGER,
    id_venta INTEGER,
    cantidad INTEGER CHECK (cantidad>0),
    precio_en_venta INTEGER,
    PRIMARY KEY (id_producto,id_venta),
    FOREIGN KEY (id_producto) REFERENCES Producto(id_producto),
    FOREIGN KEY (id_venta) REFERENCES Venta(id_venta)
);


CREATE OR REPLACE FUNCTION verificar_stock_fn() RETURNS trigger AS $$
DECLARE
    stock_actual INTEGER;
    sucursal_venta INTEGER;
BEGIN
    -- Obtener sucursal de la venta
    SELECT id_sucursal INTO sucursal_venta
    FROM Venta
    WHERE id_venta = NEW.id_venta;

    IF sucursal_venta IS NULL THEN
        RAISE EXCEPTION 'No se encontró la venta con id %', NEW.id_venta;
    END IF;

    -- Obtener stock actual del producto en la sucursal
    SELECT stock INTO stock_actual
    FROM ProductoEnSucursal
    WHERE id_producto = NEW.id_producto
      AND id_sucursal = sucursal_venta;

    IF stock_actual IS NULL THEN
        RAISE EXCEPTION 'No se encontró el producto % en la sucursal %',
            NEW.id_producto, sucursal_venta;
    END IF;

    -- Verificar si hay suficiente stock
    IF stock_actual < NEW.cantidad THEN
        RAISE EXCEPTION 'Stock insuficiente para el producto % en sucursal %',
            NEW.id_producto, sucursal_venta;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER VerificarStockEnVenta
BEFORE INSERT ON ProductoEnVenta
FOR EACH ROW
EXECUTE PROCEDURE verificar_stock_fn();

CREATE OR REPLACE FUNCTION actualizar_stock() RETURNS trigger AS $$
DECLARE
    stock_actual INTEGER;
    sucursal_venta INTEGER;
BEGIN
    -- Obtener sucursal de la venta
    SELECT id_sucursal INTO sucursal_venta
    FROM Venta
    WHERE id_venta = NEW.id_venta;

    IF sucursal_venta IS NULL THEN
        RAISE EXCEPTION 'No se encontró la venta con id %', NEW.id_venta;
    END IF;

    UPDATE ProductoEnSucursal
    SET stock = stock - NEW.cantidad
    WHERE id_producto = NEW.id_producto AND id_sucursal = sucursal_venta;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ActualizarStockDespuesDeVenta
AFTER INSERT ON ProductoEnVenta
FOR EACH ROW
EXECUTE PROCEDURE actualizar_stock();

CREATE OR REPLACE FUNCTION actualizar_stock_sucursal_despues_compra()
RETURNS TRIGGER AS $$
DECLARE
    sucursal_id INTEGER;
BEGIN
    -- Obtener la sucursal asociada a la compra
    SELECT Compra.id_sucursal INTO sucursal_id
    FROM Compra
    WHERE id_compra = NEW.id_compra;

    IF sucursal_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró la sucursal de la compra con ID %', NEW.id_compra;
    END IF;

    -- Verificar si el producto ya existe en la sucursal
    IF EXISTS (
        SELECT 1 FROM ProductoEnSucursal AS p
        WHERE p.id_producto = NEW.id_producto AND p.id_sucursal = sucursal_id
    ) THEN
        -- Si existe, actualizar el stock
        UPDATE ProductoEnSucursal AS p
        SET stock = stock + NEW.cantidad
        WHERE p.id_producto = NEW.id_producto AND p.id_sucursal = sucursal_id;
    ELSE
        -- Si no existe, insertar nuevo registro
        INSERT INTO ProductoEnSucursal (id_producto, id_sucursal, stock)
        VALUES (NEW.id_producto, sucursal_id, NEW.cantidad);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER agregar_o_actualizar_stock
AFTER INSERT ON ProductoEnCompra
FOR EACH ROW
EXECUTE PROCEDURE actualizar_stock_sucursal_despues_compra();

CREATE OR REPLACE FUNCTION validar_y_actualizar_estado_venta()
RETURNS TRIGGER AS $$
DECLARE
    monto_total_venta INTEGER;
    monto_pagado_previamente INTEGER;
    monto_final INTEGER;
BEGIN
    -- Total de la venta
    SELECT COALESCE(SUM(precio_en_venta * cantidad), 0)
    INTO monto_total_venta
    FROM ProductoEnVenta
    WHERE id_venta = NEW.id_venta;

    -- Total pagado hasta ahora
    SELECT COALESCE(SUM(monto), 0)
    INTO monto_pagado_previamente
    FROM PagoDeVenta
    WHERE id_venta = NEW.id_venta;

    -- Total pagado luego de este nuevo pago
    monto_final := monto_pagado_previamente + NEW.monto;

    -- Validar que el pago no exceda el monto de la venta
    IF monto_final > monto_total_venta THEN
        RAISE EXCEPTION 'El monto total pagado excede el valor total de la venta.';
    END IF;

    -- Actualizar el estado según el progreso del pago
    IF monto_final = monto_total_venta THEN
        UPDATE Venta SET estado = 'Pagada' WHERE id_venta = NEW.id_venta;
    ELSIF monto_final > 0 THEN
        UPDATE Venta SET estado = 'Parcial' WHERE id_venta = NEW.id_venta;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER verificar_y_actualizar_pago
BEFORE INSERT ON PagoDeVenta
FOR EACH ROW
EXECUTE PROCEDURE validar_y_actualizar_estado_venta();