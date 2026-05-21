
-- ============================================================
--  LabManager — Seed : Données de test
-- ============================================================
-- Mot de passe pour tous les comptes de test : "Password123"
-- Hash bcrypt généré avec saltRounds=10
 
-- ─── Utilisateurs de test ────────────────────────────────────
INSERT INTO utilisateurs (nom, prenom, email, mot_de_passe_hash, role)
VALUES
  ('Admin',    'Labo',    'admin@univ.mg',      '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin'),
  ('Rakoto',   'Jean',    'jean@univ.mg',        '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'enseignant'),
  ('Rabe',     'Marie',   'marie@univ.mg',       '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'etudiant'),
  ('Andry',    'Paul',    'paul@univ.mg',        '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'etudiant')
ON CONFLICT (email) DO NOTHING;
 
-- ─── Équipements de test ─────────────────────────────────────
INSERT INTO equipements (nom, type, numero_serie, date_acquisition, statut, description)
VALUES
  ('PC_01',        'ordinateur',    'SN-PC-001', '2022-01-15', 'Disponible',  'Poste de travail standard'),
  ('PC_02',        'ordinateur',    'SN-PC-002', '2022-01-15', 'Disponible',  'Poste de travail standard'),
  ('PC_03',        'ordinateur',    'SN-PC-003', '2022-01-15', 'En panne',    'Problème carte mère'),
  ('PC_04',        'ordinateur',    'SN-PC-004', '2022-03-10', 'Disponible',  'Poste de travail standard'),
  ('PC_05',        'ordinateur',    'SN-PC-005', '2022-03-10', 'Disponible',  'Poste de travail standard'),
  ('Projecteur_01','vidéoprojecteur','SN-VP-001', '2021-09-01', 'Disponible',  'Epson EB-X51'),
  ('Imprimante_01','imprimante',    'SN-IMP-001','2020-06-20', 'En maintenance','Révision annuelle'),
  ('Switch_01',    'switch',        'SN-SW-001', '2020-01-10', 'Disponible',  'Switch 24 ports')
ON CONFLICT (numero_serie) DO NOTHING;
 