-- Migración: Crear tabla de devoluciones (refunds)
-- Fecha: 2025-12-23
-- Descripción: Sistema de devoluciones por excedentes de presupuesto

CREATE TYPE refund_status AS ENUM ('pending', 'partial', 'completed', 'waived', 'disputed', 'overdue');
CREATE TYPE refund_method AS ENUM ('cash', 'transfer', 'payroll', 'check', 'other');

CREATE TABLE refunds (
    id SERIAL PRIMARY KEY,
    trip_id INTEGER NOT NULL REFERENCES trips(id) ON DELETE CASCADE,
    report_id INTEGER REFERENCES reports(id) ON DELETE SET NULL,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    
    -- Montos (en centavos)
    budget_amount INTEGER NOT NULL,
    total_expenses INTEGER NOT NULL,
    excess_amount INTEGER NOT NULL,
    refunded_amount INTEGER DEFAULT 0,
    
    -- Estado y método
    status refund_status DEFAULT 'pending' NOT NULL,
    refund_method refund_method,
    
    -- Fechas
    due_date TIMESTAMP,
    completed_date TIMESTAMP,
    
    -- Notas
    notes TEXT,
    admin_notes TEXT,
    waive_reason TEXT,
    
    -- Comprobantes
    receipt_url VARCHAR(500),
    
    -- Timestamps
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    
    -- Índices
    CONSTRAINT positive_amounts CHECK (
        budget_amount >= 0 AND
        total_expenses >= 0 AND
        excess_amount >= 0 AND
        refunded_amount >= 0
    )
);

-- Índices para mejorar rendimiento
CREATE INDEX idx_refunds_user_id ON refunds(user_id);
CREATE INDEX idx_refunds_trip_id ON refunds(trip_id);
CREATE INDEX idx_refunds_status ON refunds(status);
CREATE INDEX idx_refunds_due_date ON refunds(due_date);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION update_refunds_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_refunds_timestamp
    BEFORE UPDATE ON refunds
    FOR EACH ROW
    EXECUTE FUNCTION update_refunds_updated_at();

-- Comentarios
COMMENT ON TABLE refunds IS 'Devoluciones por excedentes de presupuesto en viajes';
COMMENT ON COLUMN refunds.budget_amount IS 'Presupuesto original del viaje (centavos)';
COMMENT ON COLUMN refunds.total_expenses IS 'Total gastado en el viaje (centavos)';
COMMENT ON COLUMN refunds.excess_amount IS 'Excedente a devolver (centavos)';
COMMENT ON COLUMN refunds.refunded_amount IS 'Monto ya devuelto (centavos)';
COMMENT ON COLUMN refunds.due_date IS 'Fecha límite para devolver';
COMMENT ON COLUMN refunds.waive_reason IS 'Razón por la que el admin exoneró la devolución';
