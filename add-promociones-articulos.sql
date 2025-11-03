-- ============================================================================
-- AGREGAR CAMPOS DE PROMOCIÓN A LA TABLA PRODUCTOS
-- ============================================================================
-- Descripción: Agrega campos para gestionar ofertas y descuentos con vigencia
-- Fecha de creación: 2025-11-03
-- ============================================================================

-- Agregar columnas de promoción
ALTER TABLE public.productos
ADD COLUMN IF NOT EXISTS precio_oferta numeric(10,2) NULL,
ADD COLUMN IF NOT EXISTS descuento_porcentual numeric(5,2) NULL CHECK (descuento_porcentual >= 0 AND descuento_porcentual <= 100),
ADD COLUMN IF NOT EXISTS fecha_vigencia_desde date NULL,
ADD COLUMN IF NOT EXISTS fecha_vigencia_hasta date NULL;

-- Comentarios para documentar los campos
COMMENT ON COLUMN public.productos.precio_oferta IS 'Precio con descuento aplicado. Se puede calcular automáticamente desde descuento_porcentual o ingresarse manualmente';
COMMENT ON COLUMN public.productos.descuento_porcentual IS 'Porcentaje de descuento aplicado al precio (0-100). Se calcula automáticamente si se ingresa precio_oferta';
COMMENT ON COLUMN public.productos.fecha_vigencia_desde IS 'Fecha de inicio de vigencia de la oferta';
COMMENT ON COLUMN public.productos.fecha_vigencia_hasta IS 'Fecha de fin de vigencia de la oferta';

-- Crear índices para optimizar consultas de promociones vigentes
CREATE INDEX IF NOT EXISTS productos_fecha_vigencia_idx
ON public.productos (fecha_vigencia_desde, fecha_vigencia_hasta)
WHERE precio_oferta IS NOT NULL;

CREATE INDEX IF NOT EXISTS productos_precio_oferta_idx
ON public.productos (precio_oferta)
WHERE precio_oferta IS NOT NULL;

-- ============================================================================
-- FUNCIÓN: calcular_precio_oferta_desde_descuento
-- Descripción: Calcula el precio de oferta cuando se ingresa un descuento
-- ============================================================================
CREATE OR REPLACE FUNCTION public.calcular_precio_oferta_desde_descuento()
RETURNS TRIGGER AS $$
BEGIN
    -- Si se ingresó descuento_porcentual pero no precio_oferta
    IF NEW.descuento_porcentual IS NOT NULL AND
       (OLD.descuento_porcentual IS NULL OR NEW.descuento_porcentual != OLD.descuento_porcentual) THEN
        -- Calcular precio_oferta basado en el descuento
        NEW.precio_oferta := NEW.precio * (1 - NEW.descuento_porcentual / 100);
    END IF;

    -- Si se ingresó precio_oferta pero no descuento_porcentual
    IF NEW.precio_oferta IS NOT NULL AND
       (OLD.precio_oferta IS NULL OR NEW.precio_oferta != OLD.precio_oferta) THEN
        -- Calcular descuento_porcentual basado en precio_oferta
        IF NEW.precio > 0 THEN
            NEW.descuento_porcentual := ((NEW.precio - NEW.precio_oferta) / NEW.precio) * 100;
        END IF;
    END IF;

    -- Si se cambió el precio base, recalcular precio_oferta si existe descuento
    IF NEW.precio != OLD.precio AND NEW.descuento_porcentual IS NOT NULL THEN
        NEW.precio_oferta := NEW.precio * (1 - NEW.descuento_porcentual / 100);
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- TRIGGER: trigger_calcular_precio_oferta
-- Descripción: Ejecuta el cálculo automático de precio_oferta/descuento
-- ============================================================================
DROP TRIGGER IF EXISTS trigger_calcular_precio_oferta ON public.productos;

CREATE TRIGGER trigger_calcular_precio_oferta
    BEFORE INSERT OR UPDATE ON public.productos
    FOR EACH ROW
    EXECUTE FUNCTION public.calcular_precio_oferta_desde_descuento();

-- ============================================================================
-- FIN DEL SCRIPT
-- ============================================================================
