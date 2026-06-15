-- Migration non destructive v1.1.0
-- Ajoute une colonne category et de nouveaux produits sans supprimer les existants

ALTER TABLE products ADD COLUMN IF NOT EXISTS category TEXT;

INSERT INTO products (name, description, price_cents, category) VALUES
  ('Casque audio', 'Casque Bluetooth avec réduction de bruit active.', 8990, 'audio'),
  ('Webcam HD', 'Webcam 1080p pour visioconférence.', 4990, 'video'),
  ('Hub USB-C', 'Hub 7-en-1 avec HDMI, USB-A, SD.', 3490, 'accessoires')
ON CONFLICT DO NOTHING;
