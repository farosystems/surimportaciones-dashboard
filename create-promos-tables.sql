-- Crear tabla de promociones
CREATE TABLE IF NOT EXISTS promos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  nombre VARCHAR(255) NOT NULL,
  descripcion TEXT,
  descuento_porcentaje DECIMAL(5,2) NOT NULL CHECK (descuento_porcentaje >= 0 AND descuento_porcentaje <= 100),
  fecha_inicio TIMESTAMP NOT NULL,
  fecha_fin TIMESTAMP NOT NULL,
  activa BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  CONSTRAINT valid_dates CHECK (fecha_fin > fecha_inicio)
);

-- Crear tabla de relación productos-promociones
CREATE TABLE IF NOT EXISTS promo_productos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  promo_id UUID NOT NULL REFERENCES promos(id) ON DELETE CASCADE,
  producto_id UUID NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(promo_id, producto_id)
);

-- Crear índices para mejor rendimiento
CREATE INDEX IF NOT EXISTS idx_promos_fecha_inicio ON promos(fecha_inicio);
CREATE INDEX IF NOT EXISTS idx_promos_fecha_fin ON promos(fecha_fin);
CREATE INDEX IF NOT EXISTS idx_promos_activa ON promos(activa);
CREATE INDEX IF NOT EXISTS idx_promo_productos_promo_id ON promo_productos(promo_id);
CREATE INDEX IF NOT EXISTS idx_promo_productos_producto_id ON promo_productos(producto_id);

-- Función para actualizar updated_at
CREATE OR REPLACE FUNCTION update_promos_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger para updated_at
CREATE TRIGGER update_promos_timestamp
BEFORE UPDATE ON promos
FOR EACH ROW
EXECUTE FUNCTION update_promos_updated_at();

-- Políticas RLS (Row Level Security)
ALTER TABLE promos ENABLE ROW LEVEL SECURITY;
ALTER TABLE promo_productos ENABLE ROW LEVEL SECURITY;

-- Permitir lectura pública de promos activas
CREATE POLICY "Promos públicas legibles" ON promos
  FOR SELECT USING (activa = true);

-- Permitir CRUD completo para usuarios autenticados (admin)
CREATE POLICY "Admin puede gestionar promos" ON promos
  FOR ALL USING (auth.role() = 'authenticated');

CREATE POLICY "Admin puede gestionar promo_productos" ON promo_productos
  FOR ALL USING (auth.role() = 'authenticated');

-- Permitir lectura de productos asociados a promos activas
CREATE POLICY "Productos de promos públicas legibles" ON promo_productos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM promos WHERE promos.id = promo_productos.promo_id AND promos.activa = true
    )
  );
