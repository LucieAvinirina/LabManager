
-- ============================================================
--  LabManager — Migration 001 : Création des tables
-- ============================================================
 
-- ─── Extension UUID (optionnel) ──────────────────────────────
-- CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
 
-- ─── Table UTILISATEUR ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS utilisateurs (
  id_utilisateur    SERIAL PRIMARY KEY,
  nom               VARCHAR(50)  NOT NULL,
  prenom            VARCHAR(50)  NOT NULL,
  email             VARCHAR(100) NOT NULL UNIQUE,
  mot_de_passe_hash VARCHAR(255) NOT NULL,
  role              VARCHAR(20)  NOT NULL DEFAULT 'etudiant'
                    CHECK (role IN ('etudiant', 'enseignant', 'admin')),
  date_creation     TIMESTAMP    NOT NULL DEFAULT NOW(),
  fcm_token         VARCHAR(255),
  est_actif         BOOLEAN      NOT NULL DEFAULT TRUE
);
 
-- ─── Table EQUIPEMENT ────────────────────────────────────────
CREATE TABLE IF NOT EXISTS equipements (
  id_equipement   SERIAL PRIMARY KEY,
  nom             VARCHAR(100) NOT NULL,
  type            VARCHAR(50)  NOT NULL,
  numero_serie    VARCHAR(100) UNIQUE,
  date_acquisition DATE,
  statut          VARCHAR(30)  NOT NULL DEFAULT 'Disponible'
                  CHECK (statut IN (
                    'Disponible',
                    'En cours d''utilisation',
                    'En maintenance',
                    'En panne',
                    'Hors service'
                  )),
  description     TEXT,
  date_creation   TIMESTAMP NOT NULL DEFAULT NOW()
);
 
-- ─── Table RESERVATION ───────────────────────────────────────
CREATE TABLE IF NOT EXISTS reservations (
  id_reservation    SERIAL PRIMARY KEY,
  id_utilisateur    INT         NOT NULL REFERENCES utilisateurs(id_utilisateur) ON DELETE CASCADE,
  date_heure_debut  TIMESTAMP   NOT NULL,
  date_heure_fin    TIMESTAMP   NOT NULL,
  statut            VARCHAR(30) NOT NULL DEFAULT 'En attente'
                    CHECK (statut IN (
                      'En attente',
                      'Confirmée',
                      'Annulée',
                      'Terminée'
                    )),
  type_reservation  VARCHAR(20) NOT NULL DEFAULT 'poste'
                    CHECK (type_reservation IN ('poste', 'salle_entiere')),
  est_recurrente    BOOLEAN     NOT NULL DEFAULT FALSE,
  frequence         VARCHAR(20) CHECK (frequence IN ('hebdomadaire', NULL)),
  motif             TEXT,
  date_creation     TIMESTAMP   NOT NULL DEFAULT NOW(),
  CONSTRAINT check_dates CHECK (date_heure_fin > date_heure_debut)
);
 
-- ─── Table DETAIL_RESERVATION (liaison N-N) ──────────────────
CREATE TABLE IF NOT EXISTS details_reservation (
  id_reservation INT NOT NULL REFERENCES reservations(id_reservation) ON DELETE CASCADE,
  id_equipement  INT NOT NULL REFERENCES equipements(id_equipement)   ON DELETE CASCADE,
  commentaire    TEXT,
  PRIMARY KEY (id_reservation, id_equipement)
);
 
-- ─── Table INCIDENT ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS incidents (
  id_incident            SERIAL PRIMARY KEY,
  id_equipement          INT         NOT NULL REFERENCES equipements(id_equipement) ON DELETE CASCADE,
  id_utilisateur         INT         NOT NULL REFERENCES utilisateurs(id_utilisateur) ON DELETE CASCADE,
  description            TEXT        NOT NULL,
  date_heure_signalement TIMESTAMP   NOT NULL DEFAULT NOW(),
  statut                 VARCHAR(30) NOT NULL DEFAULT 'Nouveau'
                         CHECK (statut IN (
                           'Nouveau',
                           'En cours de traitement',
                           'Résolu',
                           'Clôturé'
                         )),
  photo_url              VARCHAR(255),
  date_resolution        TIMESTAMP
);
 
-- ─── Index utiles pour les performances ──────────────────────
CREATE INDEX IF NOT EXISTS idx_reservations_utilisateur
  ON reservations(id_utilisateur);
 
CREATE INDEX IF NOT EXISTS idx_reservations_dates
  ON reservations(date_heure_debut, date_heure_fin);
 
CREATE INDEX IF NOT EXISTS idx_incidents_equipement
  ON incidents(id_equipement);
 
CREATE INDEX IF NOT EXISTS idx_equipements_statut
  ON equipements(statut);
 
-- ─── Message de confirmation ──────────────────────────────────
DO $$ BEGIN
  RAISE NOTICE 'Tables LabManager créées avec succès';
END $$;