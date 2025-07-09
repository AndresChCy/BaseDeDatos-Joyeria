

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

SELECT c.rut, c.nombre, c.correo, v.id_venta, v.fecha, v.estado 
FROM Cliente c 
JOIN Venta v ON c.rut = v.id_cliente 
WHERE v.estado = 'Pendiente' OR v.estado = 'Parcial'; 

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