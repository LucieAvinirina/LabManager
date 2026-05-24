const express = require('express');
const router = express.Router();
const rapportsController = require('./rapports.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');
const { requireRole } = require('../../middlewares/role.middleware');
 
// ─── Routes admin seulement ───────────────────────────────────────────────────
 
// GET /api/rapports/dashboard → Tableau de bord global
router.get('/dashboard',
  verifyToken, requireRole('admin'),
  rapportsController.getDashboard
);
 
// GET /api/rapports/occupation?date_debut=...&date_fin=... → Taux d'occupation
router.get('/occupation',
  verifyToken, requireRole('admin'),
  rapportsController.getTauxOccupation
);
 
// GET /api/rapports/equipements/utilises?limite=10 → Équipements les plus utilisés
router.get('/equipements/utilises',
  verifyToken, requireRole('admin'),
  rapportsController.getEquipementsLesPlusUtilises
);
 
// GET /api/rapports/equipements/defaillants?limite=10 → Équipements les plus en panne
router.get('/equipements/defaillants',
  verifyToken, requireRole('admin'),
  rapportsController.getEquipementsLesPlusDefaillants
);
 
// GET /api/rapports/utilisateurs → Réservations par utilisateur
router.get('/utilisateurs',
  verifyToken, requireRole('admin'),
  rapportsController.getReservationsParUtilisateur
);
 
// GET /api/rapports/export/csv?date_debut=...&date_fin=... → Export CSV
router.get('/export/csv',
  verifyToken, requireRole('admin'),
  rapportsController.exportCSV
);
 
// ─── Routes admin + enseignant ────────────────────────────────────────────────
 
// GET /api/rapports/mes-stats → Statistiques personnelles
router.get('/mes-stats',
  verifyToken, requireRole('admin', 'enseignant'),
  rapportsController.getStatsPersonnelles
);
 
module.exports = router;