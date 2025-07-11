SELECT * FROM get_stock(1,NULL);

----

SELECT * FROM get_stock(1,1);

SELECT * FROM ganancias_por_sucursal(7,2025);

SELECT * FROM ganancias_por_mes(7,2025);

SELECT c.rut, c.nombre, c.correo, v.id_venta, v.fecha, v.estado 
FROM Cliente c 
JOIN Venta v ON c.rut = v.id_cliente 
WHERE v.estado = 'Pendiente' OR v.estado = 'Parcial'; 

SELECT * FROM pagos_del_cliente(14980301)

SELECT * FROM pagos_del_cliente(16831227)

SELECT * FROM estado_de_ventas_por_cliente(14980301)

SELECT * FROM estado_general_del_cliente(14980301)

SELECT * FROM buscar_cliente_por_nombre('Juan')