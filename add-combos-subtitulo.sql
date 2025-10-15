-- Agregar campo combos_subtitulo a la configuración web
ALTER TABLE configuracion_web
ADD COLUMN IF NOT EXISTS combos_subtitulo TEXT;

-- Comentario sobre la nueva columna
COMMENT ON COLUMN configuracion_web.combos_subtitulo IS 'Subtítulo para la sección de combos en home';

-- Mostrar el estado actual
SELECT id, combos_subtitulo FROM configuracion_web;
