-- CASO 1: LISTADO DE CLIENTES

SELECT
    REPLACE(TO_CHAR(c.numrun, 'FM99,999,999'), ',', '.')
        || '-' || c.dvrun                                   AS "RUT Cliente",
    INITCAP(c.pnombre || ' ' || c.appaterno)                AS "Nombre Cliente",
    UPPER(po.nombre_prof_ofic)                              AS "Profesión Cliente",
    TO_CHAR(c.fecha_inscripcion, 'DD-MM-YYYY')              AS "Fecha de Inscripción",
    NVL(c.direccion, 'Sin dirección')                       AS "Dirección Cliente"
FROM cliente c
    JOIN profesion_oficio po
        ON po.cod_prof_ofic = c.cod_prof_ofic
    JOIN tipo_cliente tc
        ON tc.cod_tipo_cliente = c.cod_tipo_cliente
WHERE UPPER(tc.nombre_tipo_cliente) = 'TRABAJADORES DEPENDIENTES'
  AND UPPER(po.nombre_prof_ofic) IN ('CONTADOR', 'VENDEDOR')
  AND EXTRACT(YEAR FROM c.fecha_inscripcion) >
        (SELECT ROUND(AVG(EXTRACT(YEAR FROM c2.fecha_inscripcion)))
           FROM cliente c2)
ORDER BY c.numrun ASC;

-- CASO 2: AUMENTO DE CRÉDITO

-- Elimina la tabla si ya existe (permite re-ejecutar el script sin errores)

BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE clientes_cupos_compra PURGE';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -942 THEN
            RAISE;
        END IF;
END;
/

CREATE TABLE clientes_cupos_compra AS
SELECT
    CONCAT(TO_CHAR(c.numrun), '-' || UPPER(c.dvrun))        AS rut_cliente,
    TRUNC(MONTHS_BETWEEN(SYSDATE, c.fecha_nacimiento) / 12) AS edad,
    '$' || REPLACE(TO_CHAR(tc.cupo_disp_compra, 'FM999,999,999'), ',', '.')
                                                            AS cupo_disponible_compra,
    UPPER(tic.nombre_tipo_cliente)                          AS tipo_cliente
FROM cliente c
    JOIN tarjeta_cliente tc
        ON tc.numrun = c.numrun
    JOIN tipo_cliente tic
        ON tic.cod_tipo_cliente = c.cod_tipo_cliente
WHERE tc.cupo_disp_compra >=
        (SELECT MAX(tc2.cupo_disp_compra)
           FROM tarjeta_cliente tc2
          WHERE EXTRACT(YEAR FROM tc2.fecha_solic_tarjeta) =
                EXTRACT(YEAR FROM SYSDATE) - 1)
ORDER BY edad ASC;

-- Verificación del resultado almacenado
SELECT * FROM clientes_cupos_compra;
