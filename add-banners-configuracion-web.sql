-- Agregar campos de banners a la tabla configuracion_web
-- Ejecutar este script en el SQL Editor de Supabase

-- Agregar las columnas de banners
ALTER TABLE public.configuracion_web
ADD COLUMN banner_1 TEXT,
ADD COLUMN banner_2 TEXT,
ADD COLUMN banner_3 TEXT;

-- Agregar comentarios para documentación
COMMENT ON COLUMN configuracion_web.banner_1 IS 'URL o path de la primera imagen de banner para el home';
COMMENT ON COLUMN configuracion_web.banner_2 IS 'URL o path de la segunda imagen de banner para el home';
COMMENT ON COLUMN configuracion_web.banner_3 IS 'URL o path de la tercera imagen de banner para el home';

-- Crear índices parciales para banners (solo cuando no son nulos)
CREATE INDEX IF NOT EXISTS configuracion_web_banner_1_idx ON public.configuracion_web (banner_1) WHERE banner_1 IS NOT NULL;
CREATE INDEX IF NOT EXISTS configuracion_web_banner_2_idx ON public.configuracion_web (banner_2) WHERE banner_2 IS NOT NULL;
CREATE INDEX IF NOT EXISTS configuracion_web_banner_3_idx ON public.configuracion_web (banner_3) WHERE banner_3 IS NOT NULL;

-- Verificar los cambios
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'configuracion_web'
AND column_name LIKE 'banner_%'
ORDER BY column_name;
