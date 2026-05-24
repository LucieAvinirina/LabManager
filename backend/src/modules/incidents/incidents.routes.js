const express = require('express');
const router = express.Router();
const incidentsController = require('./incidents.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');
const { requireRole } = require('../../middlewares/role.middleware');
 
// GET /api/incidents → Liste des incidents (filtrée selon rôle)
router.get('/', verifyToken, incidentsController.getAll);
 
// GET /api/incidents/stats → Statistiques (admin + enseignant)
router.get('/stats', verifyToken, requireRole('admin', 'enseignant'), incidentsController.getStats);
 
// GET /api/incidents/equipement/:id_equipement → Incidents d'un équipement
router.get('/equipement/:id_equipement', verifyToken, requireRole('admin', 'enseignant'), incidentsController.getByEquipement);
 
// GET /api/incidents/:id → Détail d'un incident
router.get('/:id', verifyToken, incidentsController.getById);
 
// POST /api/incidents → Signaler un incident (tous les rôles)
router.post('/', verifyToken, incidentsController.create);
 
// PATCH /api/incidents/:id/statut → Mettre à jour statut (admin seulement)
router.patch('/:id/statut', verifyToken, requireRole('admin'), incidentsController.updateStatut);
 
module.exports = router;
 