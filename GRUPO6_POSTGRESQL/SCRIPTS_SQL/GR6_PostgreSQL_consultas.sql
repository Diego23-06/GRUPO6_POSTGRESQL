-- =====================================================================
-- NORTHWIND en PostgreSQL 18
-- Fundamentos de Bases de Datos | EPN | 2026-B | Grupo GR2SW
-- 34 ejemplos de consultas (SELECT, JOIN, UPDATE, DELETE)
--
-- Contenido
--   Parte 1  SELECT básicos                      ejemplos  1 a  8
--   Parte 2  Funciones integradas                ejemplos  9 a 14
--   Parte 3  Agregados, GROUP BY y HAVING        ejemplos 15 a 20
--   Parte 4  INNER JOIN                          ejemplos 21 a 22
--   Parte 5  LEFT JOIN                           ejemplos 23 a 24
--   Parte 6  RIGHT JOIN                          ejemplos 25 a 26
--   Parte 7  UPDATE                              ejemplos 27 a 30
--   Parte 8  DELETE                              ejemplos 31 a 34
--
-- Integrantes:
-- Diego Martinez
-- Rosalia Piedra
-- Esteban Quinapanta
-- Daniela Vivanco 
-- =====================================================================


-- =====================================================================
-- PARTE 1: SELECT básicos (ejemplos 1 a 8)
-- =====================================================================

-- Ejemplo 1: formato con funciones
-- Nombre del producto en mayúsculas y precio con formato de moneda.
SELECT UPPER(product_name) AS producto,
       TO_CHAR(unit_price, 'FM$999,990.00') AS precio,
       units_in_stock AS stock
FROM products
ORDER BY product_id
LIMIT 15;


-- Ejemplo 2: formato con funciones
-- Empleado con nombre completo y fecha de ingreso formateada.
SELECT first_name || ' ' || UPPER(last_name) AS empleado,
       title AS cargo,
       TO_CHAR(hire_date, 'DD/MM/YYYY') AS fecha_ingreso
FROM employees
ORDER BY employee_id;


-- Ejemplo 3: WHERE y ORDER BY
-- Productos activos con precio mayor a 30, del más caro al más barato.
SELECT product_id,
       product_name,
       unit_price
FROM products
WHERE unit_price > 30
  AND discontinued = 0
ORDER BY unit_price DESC;


-- Ejemplo 4: WHERE y ORDER BY
-- Clientes de Alemania ordenados por nombre de empresa.
SELECT customer_id,
       company_name,
       contact_name,
       city
FROM customers
WHERE country = 'Germany'
ORDER BY company_name ASC;


-- Ejemplo 5: BETWEEN
-- Pedidos realizados entre el 8 y el 12 de julio de 1996.
SELECT order_id,
       customer_id,
       order_date,
       freight
FROM orders
WHERE order_date BETWEEN '1996-07-08' AND '1996-07-12'
ORDER BY order_date, order_id;


-- Ejemplo 6: LIKE
-- Clientes cuyo nombre de empresa empieza con 'B'.
SELECT customer_id,
       company_name,
       city,
       country
FROM customers
WHERE company_name LIKE 'B%'
ORDER BY company_name;


-- Ejemplo 7: IN
-- Clientes de Alemania, Francia o Suecia.
SELECT customer_id,
       company_name,
       country
FROM customers
WHERE country IN ('Germany', 'France', 'Sweden')
ORDER BY country, company_name;


-- Ejemplo 8: DISTINCT
-- Países distintos donde hay clientes.
SELECT DISTINCT country
FROM customers
ORDER BY country;


-- =====================================================================
-- PARTE 2: Funciones integradas de fecha, texto y numéricas
--          (ejemplos 9 a 14)
--
-- Equivalencias con SQL Server:
--   DATEADD  -> operador + INTERVAL     DATEDIFF -> resta de fechas
--   DATENAME -> TO_CHAR                 DATEPART -> EXTRACT
--   DAY      -> EXTRACT(DAY FROM ...)   RIGHT    -> RIGHT (igual)
-- =====================================================================

-- Ejemplo 9: fecha (equivalente a DATEADD)
-- Fecha límite de pago: fecha del pedido más 30 días, y un mes después.
SELECT order_id,
       order_date AS fecha_pedido,
       (order_date + INTERVAL '30 days')::DATE AS fecha_limite_pago,
       (order_date + INTERVAL '1 month')::DATE AS un_mes_despues
FROM orders
ORDER BY order_id
LIMIT 15;


-- Ejemplo 10: fecha y numérica (equivalente a DATEDIFF, con ROUND)
-- Días entre el pedido y el envío, y flete promedio por día.
SELECT order_id,
       order_date AS fecha_pedido,
       shipped_date AS fecha_envio,
       (shipped_date - order_date) AS dias_hasta_envio,
       ROUND((freight / NULLIF(shipped_date - order_date, 0))::numeric, 2) AS flete_por_dia
FROM orders
WHERE shipped_date IS NOT NULL
ORDER BY dias_hasta_envio DESC, order_id
LIMIT 15;


-- Ejemplo 11: fecha (equivalente a DATENAME)
-- Nombre del día de la semana y del mes en que se hizo el pedido.
SELECT order_id,
       order_date AS fecha_pedido,
       TRIM(TO_CHAR(order_date, 'Day')) AS nombre_dia,
       TRIM(TO_CHAR(order_date, 'Month')) AS nombre_mes
FROM orders
ORDER BY order_date, order_id
LIMIT 15;


-- Ejemplo 12: fecha (equivalente a DATEPART)
-- Año, trimestre, mes y semana del año de cada pedido.
SELECT order_id,
       order_date AS fecha_pedido,
       EXTRACT(YEAR FROM order_date) AS anio,
       EXTRACT(QUARTER FROM order_date) AS trimestre,
       EXTRACT(MONTH FROM order_date) AS mes,
       EXTRACT(WEEK FROM order_date) AS semana_anio
FROM orders
ORDER BY order_id
LIMIT 15;


-- Ejemplo 13: fecha y numéricas (equivalente a DAY)
-- Día del mes de envío, flete con 15 % de IVA y flete redondeado hacia arriba.
SELECT order_id,
       shipped_date AS fecha_envio,
       EXTRACT(DAY FROM shipped_date) AS dia_envio,
       freight,
       ROUND((freight * 1.15)::numeric, 1) AS flete_con_iva_15,
       CEIL(freight) AS flete_redondeado_arriba
FROM orders
WHERE shipped_date IS NOT NULL
ORDER BY dia_envio, order_id
LIMIT 15;


-- Ejemplo 14: texto (RIGHT y LENGTH)
-- Últimos caracteres del código del cliente y del nombre de la empresa.
SELECT customer_id,
       RIGHT(customer_id, 3) AS ultimos_3_codigo,
       company_name,
       RIGHT(company_name, 4) AS ultimos_4_nombre,
       LENGTH(company_name) AS longitud_nombre
FROM customers
ORDER BY customer_id
LIMIT 15;


-- =====================================================================
-- PARTE 3: Funciones de agregado, GROUP BY y HAVING (ejemplos 15 a 20)
-- =====================================================================

-- Ejemplo 15: COUNT con GROUP BY y HAVING
-- Cantidad de clientes por país, solo países con 5 o más clientes.
SELECT country AS pais,
       COUNT(*) AS total_clientes
FROM customers
GROUP BY country
HAVING COUNT(*) >= 5
ORDER BY total_clientes DESC, pais;


-- Ejemplo 16: SUM y COUNT con GROUP BY y HAVING
-- Total de cada pedido (precio x cantidad con descuento), solo pedidos
-- cuyo total supere 5000.
SELECT order_id AS pedido,
       COUNT(product_id) AS lineas_detalle,
       ROUND(SUM(unit_price * quantity * (1 - discount))::numeric, 2) AS total_pedido
FROM order_details
GROUP BY order_id
HAVING SUM(unit_price * quantity * (1 - discount)) > 5000
ORDER BY total_pedido DESC;


-- Ejemplo 17: AVG, MIN, MAX y COUNT con GROUP BY y HAVING
-- Estadísticas de precios por categoría, solo categorías con precio
-- promedio mayor a 25.
SELECT category_id AS categoria,
       COUNT(*) AS total_productos,
       ROUND(AVG(unit_price)::numeric, 2) AS precio_promedio,
       MIN(unit_price) AS precio_minimo,
       MAX(unit_price) AS precio_maximo
FROM products
GROUP BY category_id
HAVING AVG(unit_price) > 25
ORDER BY precio_promedio DESC;


-- Ejemplo 18: COUNT con GROUP BY y HAVING
-- Pedidos atendidos por cada empleado, solo empleados con más de 100.
SELECT employee_id AS empleado,
       COUNT(*) AS total_pedidos
FROM orders
GROUP BY employee_id
HAVING COUNT(*) > 100
ORDER BY total_pedidos DESC;


-- Ejemplo 19: SUM, AVG y COUNT con GROUP BY y HAVING
-- Costo de flete por país de envío, solo países con flete total mayor a 1000.
SELECT ship_country AS pais_envio,
       COUNT(*) AS total_pedidos,
       ROUND(SUM(freight)::numeric, 2) AS flete_total,
       ROUND(AVG(freight)::numeric, 2) AS flete_promedio
FROM orders
GROUP BY ship_country
HAVING SUM(freight) > 1000
ORDER BY flete_total DESC;


-- Ejemplo 20: SUM y MAX con GROUP BY y HAVING
-- Unidades vendidas por producto, solo productos con más de 1000 unidades.
SELECT product_id AS producto,
       SUM(quantity) AS unidades_vendidas,
       MAX(quantity) AS mayor_cantidad_en_una_linea
FROM order_details
GROUP BY product_id
HAVING SUM(quantity) > 1000
ORDER BY unidades_vendidas DESC;


-- =====================================================================
-- PARTE 4: INNER JOIN (ejemplos 21 a 22)
-- =====================================================================

-- Ejemplo 21: INNER JOIN de 2 tablas (products y categories)
-- Productos con precio mayor a 30 junto con el nombre de su categoría.
SELECT p.product_id AS codigo,
       p.product_name AS producto,
       c.category_name AS categoria,
       p.unit_price AS precio
FROM products p
INNER JOIN categories c ON p.category_id = c.category_id
WHERE p.unit_price > 30
ORDER BY c.category_name, p.product_name;


-- Ejemplo 22: INNER JOIN de 3 tablas (orders, customers y employees)
-- Pedidos con el nombre del cliente y del empleado que los atendió
-- (se muestran los primeros 15).
SELECT o.order_id AS pedido,
       c.company_name AS cliente,
       e.first_name || ' ' || e.last_name AS empleado,
       o.order_date AS fecha_pedido,
       o.ship_country AS pais_envio
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
INNER JOIN employees e ON o.employee_id = e.employee_id
ORDER BY o.order_id
LIMIT 15;


-- =====================================================================
-- PARTE 5: LEFT JOIN (ejemplos 23 a 24)
-- =====================================================================

-- Ejemplo 23: LEFT JOIN (customers y orders)
-- Clientes que nunca han realizado un pedido.
SELECT c.customer_id AS cliente,
       c.company_name AS empresa,
       c.country AS pais,
       o.order_id AS pedido
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL
ORDER BY c.company_name;


-- Ejemplo 24: LEFT JOIN sobre la misma tabla (employees y employees)
-- Cada empleado con su jefe; quien no tiene jefe aparece como 'Sin jefe'.
SELECT e.employee_id AS codigo,
       e.first_name || ' ' || e.last_name AS empleado,
       e.title AS cargo,
       COALESCE(j.first_name || ' ' || j.last_name, 'Sin jefe') AS jefe
FROM employees e
LEFT JOIN employees j ON e.reports_to = j.employee_id
ORDER BY e.employee_id;


-- =====================================================================
-- PARTE 6: RIGHT JOIN (ejemplos 25 a 26)
-- =====================================================================

-- Ejemplo 25: RIGHT JOIN (order_details y products)
-- Los 10 productos menos vendidos; con RIGHT JOIN se conservan todos los
-- productos aunque no tengan ventas (COALESCE los muestra con 0).
SELECT p.product_id AS codigo,
       p.product_name AS producto,
       COALESCE(SUM(od.quantity), 0) AS unidades_vendidas
FROM order_details od
RIGHT JOIN products p ON od.product_id = p.product_id
GROUP BY p.product_id, p.product_name
ORDER BY unidades_vendidas ASC, p.product_name
LIMIT 10;


-- Ejemplo 26: RIGHT JOIN (products y categories)
-- Cantidad de productos y unidades en stock por categoría; con RIGHT JOIN
-- se conservan todas las categorías aunque no tengan productos.
SELECT c.category_id AS codigo,
       c.category_name AS categoria,
       COUNT(p.product_id) AS total_productos,
       COALESCE(SUM(p.units_in_stock), 0) AS unidades_en_stock
FROM products p
RIGHT JOIN categories c ON p.category_id = c.category_id
GROUP BY c.category_id, c.category_name
ORDER BY total_productos DESC, c.category_name;


-- =====================================================================
-- PARTE 7: UPDATE (ejemplos 27 a 30)
-- Cada ejemplo muestra primero las filas afectadas con un SELECT y
-- luego ejecuta el UPDATE con RETURNING para ver el resultado.
-- =====================================================================

-- Ejemplo 27: UPDATE con WHERE
-- Sube 10 % el precio de los productos de la categoría 1.
SELECT product_id, product_name, unit_price
FROM products
WHERE category_id = 1
ORDER BY product_id;

UPDATE products
SET unit_price = ROUND((unit_price * 1.10)::numeric, 2)
WHERE category_id = 1
RETURNING product_id, product_name, unit_price;


-- Ejemplo 28: UPDATE con WHERE
-- Suma 20 unidades de stock a los productos con menos de 10 en bodega.
SELECT product_id, product_name, units_in_stock
FROM products
WHERE units_in_stock < 10
ORDER BY product_id;

UPDATE products
SET units_in_stock = units_in_stock + 20
WHERE units_in_stock < 10
RETURNING product_id, product_name, units_in_stock;


-- Ejemplo 29: UPDATE con subconsulta
-- Baja 5 % el precio de los productos que cuestan más que el promedio.
SELECT product_id, product_name, unit_price
FROM products
WHERE unit_price > (SELECT AVG(unit_price) FROM products)
ORDER BY product_id;

UPDATE products
SET unit_price = ROUND((unit_price * 0.95)::numeric, 2)
WHERE unit_price > (SELECT AVG(unit_price) FROM products)
RETURNING product_id, product_name, unit_price;


-- Ejemplo 30: UPDATE con subconsulta
-- Sube 1 el precio de los productos de la categoría 'Beverages'.
SELECT product_id, product_name, unit_price
FROM products
WHERE category_id IN (SELECT category_id FROM categories WHERE category_name = 'Beverages')
ORDER BY product_id;

UPDATE products
SET unit_price = unit_price + 1
WHERE category_id IN (SELECT category_id FROM categories WHERE category_name = 'Beverages')
RETURNING product_id, product_name, unit_price;


-- =====================================================================
-- PARTE 8: DELETE (ejemplos 31 a 34)
-- Cada ejemplo inserta filas de prueba, muestra la tabla, elimina con
-- WHERE y RETURNING, y vuelve a mostrar la tabla para comprobarlo.
-- =====================================================================

-- Ejemplo 31: DELETE con WHERE (igualdad)
-- Elimina un transportista de prueba por su nombre exacto.
INSERT INTO shippers (shipper_id, company_name, phone) VALUES (7, 'Prueba Envios A', '000-0001');
INSERT INTO shippers (shipper_id, company_name, phone) VALUES (8, 'Prueba Envios B', '000-0002');

SELECT * FROM shippers ORDER BY shipper_id;

DELETE FROM shippers WHERE company_name = 'Prueba Envios A' RETURNING *;

SELECT * FROM shippers ORDER BY shipper_id;


-- Ejemplo 32: DELETE con WHERE (LIKE)
-- Elimina los transportistas de prueba que quedan, por patrón de nombre.
SELECT * FROM shippers WHERE company_name LIKE 'Prueba Envios%';

DELETE FROM shippers WHERE company_name LIKE 'Prueba Envios%' RETURNING *;

SELECT * FROM shippers ORDER BY shipper_id;


-- Ejemplo 33: DELETE con WHERE
-- Elimina una categoría de prueba por su nombre.
INSERT INTO categories (category_id, category_name, description) VALUES (9, 'Categoria Prueba', 'Solo para DELETE');

SELECT category_id, category_name FROM categories ORDER BY category_id;

DELETE FROM categories WHERE category_name = 'Categoria Prueba' RETURNING category_id, category_name, description;

SELECT category_id, category_name FROM categories ORDER BY category_id;


-- Ejemplo 34: DELETE con WHERE
-- Elimina un cliente de prueba por su código y comprueba que ya no existe.
INSERT INTO customers (customer_id, company_name, country) VALUES ('ZZZZZ', 'Cliente Prueba', 'Ecuador');

SELECT customer_id, company_name, country FROM customers WHERE customer_id = 'ZZZZZ';

DELETE FROM customers WHERE customer_id = 'ZZZZZ' RETURNING customer_id, company_name, country;

SELECT COUNT(*) FROM customers WHERE customer_id = 'ZZZZZ';
