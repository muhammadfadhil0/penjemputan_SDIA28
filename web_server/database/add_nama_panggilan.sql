-- =====================================================
-- MIGRATION: Add nama_panggilan column to siswa table
-- SDIA 28 - Sistem Penjemputan Siswa
-- Run this after the main salam_sdia28.sql
-- =====================================================

-- Add nama_panggilan column to siswa table if not exists
ALTER TABLE siswa ADD COLUMN IF NOT EXISTS nama_panggilan VARCHAR(50) NULL AFTER nama;

-- Update existing sample data with nicknames (optional)
UPDATE siswa SET nama_panggilan = 'Farhan' WHERE nama = 'Ahmad Farhan Pratama' AND nama_panggilan IS NULL;
UPDATE siswa SET nama_panggilan = 'Aisyah' WHERE nama = 'Aisyah Putri Ramadhani' AND nama_panggilan IS NULL;
UPDATE siswa SET nama_panggilan = 'Budi' WHERE nama = 'Budi Santoso' AND nama_panggilan IS NULL;
UPDATE siswa SET nama_panggilan = 'Citra' WHERE nama = 'Citra Dewi Lestari' AND nama_panggilan IS NULL;
UPDATE siswa SET nama_panggilan = 'Dimas' WHERE nama = 'Dimas Prasetya' AND nama_panggilan IS NULL;

-- =====================================================
-- NOTE: If your MySQL version doesn't support 
-- "ADD COLUMN IF NOT EXISTS", use this instead:
-- =====================================================
-- ALTER TABLE siswa ADD COLUMN nama_panggilan VARCHAR(50) NULL AFTER nama;
-- (This will error if column already exists, which is fine)
