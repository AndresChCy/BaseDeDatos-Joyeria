# 📚 Documentación de Base de Datos para Joyas Andreita

Este repositorio contiene la definición y documentación de la base de datos utilizada en el proyecto **Joyas Andreita**. A continuación se describen las tablas, sus atributos y ejemplos de uso.

---
# 📁Tablas:
##  `Producto`
### 📄 Definición SQL

```sql
CREATE TABLE Producto (
    id_producto SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    descripcion VARCHAR(200),
    precio_actual INTEGER CHECK (precio_actual >= 0),
    imagen BYTEA,
    tipo_producto VARCHAR(10)
);
```
##  `Categoria`

### 📄 Definición SQL

```sql
CREATE TABLE Categoria (
	id_categoria SERIAL PRIMARY KEY,
	nombre VARCHAR(50),
	descripcion VARCHAR(200)
);
```
##  `Joya`

### 📄 Definición SQL

```sql
CREATE TABLE Joya (
	id_producto INTEGER PRIMARY KEY,
	peso NUMERIC(8,2) CHECK (peso>0),
	material VARCHAR(90),
	categoria INTEGER,
	FOREIGN KEY (categoria) REFERENCES Categoria(id_categoria),
	FOREIGN KEY (id_producto) REFERENCES Producto(id_producto)
);
```
##  `Perfume`

### 📄 Definición SQL

```sql
CREATE TABLE Perfume (
	id_producto INTEGER PRIMARY KEY,
	fragancia VARCHAR(60),
	marca VARCHAR(50),
	mililitros INTEGER,
	FOREIGN KEY (id_producto) REFERENCES Producto(id_producto)
);
```
##  `Joyero`

### 📄 Definición SQL

```sql
CREATE TABLE Joyero (
	id_producto INTEGER PRIMARY KEY,
	ancho NUMERIC(4,1),
	alto NUMERIC(4,1),  
	largo NUMERIC(4,1),
	FOREIGN KEY (id_producto) REFERENCES Producto(id_producto)
);
```
##  `JoyeroAlmacenaCategoria`

### 📄 Definición SQL

```sql
CREATE TABLE JoyeroAlmacenaCategoria (
	id_categoria INTEGER,
	id_joyero INTEGER,
	cantidad INTEGER,
	PRIMARY KEY (id_categoria,id_joyero)
);
```
##  `Proveedor`

### 📄 Definición SQL

```sql
CREATE TABLE Proveedor (
	rut INTEGER PRIMARY KEY,
	correo VARCHAR(320),
	nombre VARCHAR(60)
);
```
##  `Sucursal`

### 📄 Definición SQL

```sql
CREATE TABLE Sucursal (
	id_sucursal SERIAL PRIMARY KEY,
	calle VARCHAR(50),
	numero_casa INTEGER,
	comuna VARCHAR(40)
);
```
##  `Compra`

### 📄 Definición SQL

```sql
CREATE TABLE Compra (
	id_compra SERIAL PRIMARY KEY,
	fecha DATE,
	id_proveedor INTEGER,
	id_sucursal INTEGER,
	FOREIGN KEY (id_proveedor) REFERENCES Proveedor(rut) ON UPDATE CASCADE,
	FOREIGN KEY (id_sucursal) REFERENCES Sucursal(id_sucursal) ON UPDATE CASCADE
);
```
##  `ProductoEnCompra`

### 📄 Definición SQL

```sql
CREATE TABLE ProductoEnCompra (
	id_compra INTEGER,
	id_producto INTEGER,
	cantidad INTEGER,
	precio_total INTEGER,
	PRIMARY KEY (id_compra,id_producto)
);
```
##  `ProductoEnSucursal`

### 📄 Definición SQL

```sql
CREATE TABLE ProductoEnSucursal(
	id_producto INTEGER,
	id_sucursal INTEGER,
	stock INTEGER,
	PRIMARY KEY (id_producto,id_sucursal),
	FOREIGN KEY (id_producto) REFERENCES Producto(id_producto),
	FOREIGN KEY (id_sucursal) REFERENCES Sucursal(id_sucursal)
);
```
##  `Cliente`

### 📄 Definición SQL

```sql
CREATE TABLE Cliente (
	rut INTEGER PRIMARY KEY,
	telefono INTEGER,
	calle VARCHAR(50),
	numero_casa INTEGER,
	comuna VARCHAR(40),
	correo VARCHAR(320),
	nombre VARCHAR(60)
);
```
##  `Venta`

### 📄 Definición SQL

```sql
CREATE TABLE Venta (
	id_venta SERIAL PRIMARY KEY,
	fecha DATE,
	estado VARCHAR(15) DEFAULT 'Pendiente',
	id_cliente INTEGER NOT NULL,
	id_sucursal INTEGER NOT NULL,
	FOREIGN KEY (id_cliente) REFERENCES Cliente(rut) ON UPDATE CASCADE,
	FOREIGN KEY (id_sucursal) REFERENCES Sucursal(id_sucursal) ON UPDATE CASCADE
);
```
##  `PagoDeVenta`

### 📄 Definición SQL

```sql
CREATE TABLE PagoDeVenta (
	id_pago SERIAL PRIMARY KEY,
	id_venta INTEGER,
	monto INTEGER,
	fecha DATE,
	FOREIGN KEY (id_venta) REFERENCES Venta(id_venta)
);
```

##  `ProductoEnVenta`

### 📄 Definición SQL

```sql
CREATE TABLE ProductoEnVenta (
	id_producto INTEGER,
	id_venta INTEGER,
	cantidad INTEGER,
	precio_en_venta INTEGER,
	PRIMARY KEY (id_producto,id_venta),
	FOREIGN KEY (id_producto) REFERENCES Producto(id_producto),
	FOREIGN KEY (id_venta) REFERENCES Venta(id_venta)
);
```

---

# 📎 Triggers
##  `verificar_y_actualizar_pago`

### 📄 Definición SQL

```sql
CREATE OR REPLACE TRIGGER verificar_y_actualizar_pago
BEFORE INSERT ON PagoDeVenta
FOR EACH ROW
EXECUTE FUNCTION validar_y_actualizar_estado_venta();
```

##  `agregar_o_actualizar_stock`

### 📄 Definición SQL

```sql
CREATE TRIGGER agregar_o_actualizar_stock
AFTER INSERT ON ProductoEnCompra
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock_sucursal_despues_compra();

```

##  `ActualizarStockDespuesDeVenta`

### 📄 Definición SQL

```sql
CREATE TRIGGER ActualizarStockDespuesDeVenta
AFTER INSERT ON ProductoEnVenta
FOR EACH ROW
EXECUTE FUNCTION actualizar_stock();
```

##  `VerificarStockEnVenta`

### 📄 Definición SQL

```sql
CREATE TRIGGER VerificarStockEnVenta
BEFORE INSERT ON ProductoEnVenta
FOR EACH ROW
EXECUTE FUNCTION verificar_stock_fn();
```
---

# 📐 Funciones 
##  `verificar_stock_fn()`

### 📄 Definición SQL

```sql
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
```
##  `actualizar_stock_sucursal_despues_compra()`

### 📄 Definición SQL

```sql
CREATE OR REPLACE FUNCTION actualizar_stock_sucursal_despues_compra()
RETURNS TRIGGER AS $$
DECLARE
    id_sucursal INTEGER;
BEGIN
    -- Obtener la sucursal asociada a la compra
    SELECT id_sucursal INTO id_sucursal
    FROM Compra
    WHERE id_compra = NEW.id_compra;

    IF id_sucursal IS NULL THEN
        RAISE EXCEPTION 'No se encontró la sucursal de la compra con ID %', NEW.id_compra;
    END IF;

    -- Verificar si el producto ya existe en la sucursal
    IF EXISTS (
        SELECT 1 FROM ProductoEnSucursal
        WHERE id_producto = NEW.id_producto AND id_sucursal = id_sucursal
    ) THEN
        -- Si existe, actualizar el stock
        UPDATE ProductoEnSucursal
        SET stock = stock + NEW.cantidad
        WHERE id_producto = NEW.id_producto AND id_sucursal = id_sucursal;
    ELSE
        -- Si no existe, insertar nuevo registro
        INSERT INTO ProductoEnSucursal (id_producto, id_sucursal, stock)
        VALUES (NEW.id_producto, id_sucursal, NEW.cantidad);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
```
##  `validar_y_actualizar_estado_venta()`

### 📄 Definición SQL

```sql
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
```

##  `get_stock (producto_id, sucursal_id)`

### 📄 Definición SQL

```sql
CREATE OR REPLACE FUNCTION get_stock (producto_id INTEGER, sucursal_id INTEGER)
RETURNS INTEGER AS $$ 
DECLARE 
	v_stock INTEGER;
BEGIN
	IF sucursal_id IS NULL THEN 
		SELECT COALESCE(SUM(stock),0) INTO v_stock
		FROM ProductoEnSucursal
		WHERE producto_id = id_producto;

		RETURN v_stock;
	END IF;

	SELECT stock INTO v_stock
	FROM ProductoEnSucursal
	WHERE producto_id = id_producto AND sucursal_id = id_sucursal;

	RETURN v_stock;
END;
$$ LANGUAGE plpgsql;
```
##  `ganancias_por_sucursal(mes, año)`

### 📄 Definición SQL

```sql
CREATE OR REPLACE FUNCTION ganancias_por_sucursal(
    mes_numero TEXT,
    p_anio INTEGER
)
RETURNS TABLE (
    id_sucursal INTEGER,
    total_ventas INTEGER,
    total_compras INTEGER,
    ingresos INTEGER,
    gastos INTEGER,
    ganancia INTEGER
) AS $$
DECLARE
    mes_numero INTEGER;
BEGIN
    RETURN QUERY
    SELECT 
        s.id_sucursal,

        -- Total de ventas en la sucursal
        COALESCE((
            SELECT COUNT(*) FROM Venta v
            WHERE v.id_sucursal = s.id_sucursal
              AND EXTRACT(MONTH FROM v.fecha) = mes_numero
              AND EXTRACT(YEAR FROM v.fecha) = p_anio
        ), 0) AS total_ventas,

        -- Total de compras en la sucursal
        COALESCE((
            SELECT COUNT(*) FROM Compra c
            WHERE c.id_sucursal = s.id_sucursal
              AND EXTRACT(MONTH FROM c.fecha) = mes_numero
              AND EXTRACT(YEAR FROM c.fecha) = p_anio
        ), 0) AS total_compras,

        -- Ingresos por ventas
        COALESCE((
            SELECT SUM(pv.precio_en_venta * pv.cantidad)
            FROM ProductoEnVenta pv
            JOIN Venta v ON pv.id_venta = v.id_venta
            WHERE v.id_sucursal = s.id_sucursal
              AND EXTRACT(MONTH FROM v.fecha) = mes_numero
              AND EXTRACT(YEAR FROM v.fecha) = p_anio
        ), 0) AS ingresos,

        -- Gastos por compras
        COALESCE((
            SELECT SUM(pc.precio_total)
            FROM ProductoEnCompra pc
            JOIN Compra c ON pc.id_compra = c.id_compra
            WHERE c.id_sucursal = s.id_sucursal
              AND EXTRACT(MONTH FROM c.fecha) = mes_numero
              AND EXTRACT(YEAR FROM c.fecha) = p_anio
        ), 0) AS gastos,

        -- Ganancia neta
        COALESCE((
            SELECT SUM(pv.precio_en_venta * pv.cantidad)
            FROM ProductoEnVenta pv
            JOIN Venta v ON pv.id_venta = v.id_venta
            WHERE v.id_sucursal = s.id_sucursal
              AND EXTRACT(MONTH FROM v.fecha) = mes_numero
              AND EXTRACT(YEAR FROM v.fecha) = p_anio
        ), 0)
        -
        COALESCE((
            SELECT SUM(pc.precio_total)
            FROM ProductoEnCompra pc
            JOIN Compra c ON pc.id_compra = c.id_compra
            WHERE c.id_sucursal = s.id_sucursal
              AND EXTRACT(MONTH FROM c.fecha) = mes_numero
              AND EXTRACT(YEAR FROM c.fecha) = p_anio
        ), 0) AS ganancia

    FROM Sucursal s;
END;
$$ LANGUAGE plpgsql;
```
##  `ganancias_por_mes(mes, año)`

### 📄 Definición SQL

```sql
CREATE OR REPLACE FUNCTION ganancias_por_mes(mes_numero INTEGER, p_anio INTEGER)
RETURNS TABLE (
    mes INTEGER,
    ingresos INTEGER,
    gastos INTEGER,
    ganancia INTEGER
) AS $$
DECLARE
    mes_numero INTEGER;
BEGIN
   -- Realizar las consultas
    RETURN QUERY
    SELECT 
        INITCAP(mes_numero) || ' ' || p_anio AS mes,
        
        COALESCE((
            SELECT SUM(monto)
            FROM PagoDeVenta
            WHERE EXTRACT(MONTH FROM fecha) = mes_numero
              AND EXTRACT(YEAR FROM fecha) = p_anio
        ), 0) AS ingresos,

        COALESCE((
            SELECT SUM(precio_total)
            FROM ProductoEnCompra pc
            JOIN Compra c ON pc.id_compra = c.id_compra
            WHERE EXTRACT(MONTH FROM c.fecha) = mes_numero
              AND EXTRACT(YEAR FROM c.fecha) = p_anio
        ), 0) AS gastos,

        (
            COALESCE((
                SELECT SUM(monto)
                FROM PagoDeVenta
                WHERE EXTRACT(MONTH FROM fecha) = mes_numero
                  AND EXTRACT(YEAR FROM fecha) = p_anio
            ), 0)
            -
            COALESCE((
                SELECT SUM(precio_total)
                FROM ProductoEnCompra pc
                JOIN Compra c ON pc.id_compra = c.id_compra
                WHERE EXTRACT(MONTH FROM c.fecha) = mes_numero
                  AND EXTRACT(YEAR FROM c.fecha) = p_anio
            ), 0)
        ) AS ganancia;
END;
$$ LANGUAGE plpgsql;
```

##  `pagos_del_cliente(rut)`

### 📄 Definición SQL

```sql
CREATE OR REPLACE FUNCTION pagos_del_cliente(p_rut_cliente INTEGER)
RETURNS TABLE (
    id_pago INTEGER,
    fecha DATE,
    monto INTEGER,
    id_venta INTEGER,
    estado_venta VARCHAR(15)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        p.id_pago,
        p.fecha,
        p.monto,
        v.id_venta,
        v.estado
    FROM PagoDeVenta p
    JOIN Venta v ON p.id_venta = v.id_venta
    WHERE v.id_cliente = p_rut_cliente
    ORDER BY p.fecha ASC;
END;
$$ LANGUAGE plpgsql;
```

##  `estado_de_ventas_por_cliente(rut)`

### 📄 Definición SQL

```sql
CREATE OR REPLACE FUNCTION estado_de_ventas_por_cliente(p_rut_cliente INTEGER)
RETURNS TABLE (
    id_venta INTEGER,
    precio_total INTEGER,
    total_pagado INTEGER,
    deuda INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.id_venta,

        -- Precio total: suma de precios en la venta
        COALESCE((
            SELECT SUM(precio_en_venta * cantidad)
            FROM ProductoEnVenta pv
            WHERE pv.id_venta = v.id_venta
        ), 0) AS precio_total,

        -- Total pagado
        COALESCE((
            SELECT SUM(monto)
            FROM PagoDeVenta pd
            WHERE pd.id_venta = v.id_venta
        ), 0) AS total_pagado,

        -- Deuda: precio total - pagado
        COALESCE((
            SELECT SUM(precio_en_venta * cantidad)
            FROM ProductoEnVenta pv
            WHERE pv.id_venta = v.id_venta
        ), 0)
        -
        COALESCE((
            SELECT SUM(monto)
            FROM PagoDeVenta pd
            WHERE pd.id_venta = v.id_venta
        ), 0) AS deuda

    FROM Venta v
    WHERE v.id_cliente = p_rut_cliente
    ORDER BY v.fecha;
END;
$$ LANGUAGE plpgsql;
```

##  `estado_general_del_cliente(rut)`

### 📄 Definición SQL

```sql
CREATE OR REPLACE FUNCTION estado_general_del_cliente(p_rut_cliente INTEGER)
RETURNS TABLE (
    rut_cliente INTEGER,
    total_pagado INTEGER,
    total_deuda INTEGER,
    total_ventas INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p_rut_cliente AS rut_cliente,
        COALESCE(SUM(e.total_pagado), 0) AS total_pagado,
        COALESCE(SUM(e.deuda), 0) AS total_deuda,
        COALESCE(SUM(e.precio_total), 0) AS total_ventas
    FROM estado_de_ventas_por_cliente(p_rut_cliente) e;
END;
$$ LANGUAGE plpgsql;
```

##  `buscar_cliente_por_nombre(nombre)`

### 📄 Definición SQL

```sql
CREATE OR REPLACE FUNCTION buscar_cliente_por_nombre(p_nombre TEXT)
RETURNS TABLE (
    rut INTEGER,
    telefono INTEGER,
    calle VARCHAR,
    numero_casa INTEGER,
    comuna VARCHAR,
    correo VARCHAR,
    nombre VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM Cliente
    WHERE nombre ILIKE '%' || p_nombre || '%';
END;
$$ LANGUAGE plpgsql;
```
---
# 👁️ Vistas
##  Clientes que aún no completan pago.

### 📄 Definición SQL

```sql
SELECT c.rut, c.nombre, c.correo, v.id_venta, v.fecha, v.estado 
FROM Cliente c 
JOIN Venta v ON c.rut = v.id_cliente 
WHERE v.estado = 'Pendiente' OR v.estado = 'Parcial'; 
```

<!--
##  ``

### 📄 Definición SQL

```sql

```
-->