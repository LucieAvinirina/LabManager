const express = require('express');
const router = express.Router();
const equipementsController = require('./equipements.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');
const { requireRole } = require('../../middlewares/role.middleware');
 
// ─── Routes publiques (token requis, tous les rôles) ─────────────────────────
 
// GET /api/equipements → Liste tous les équipements (avec filtres optionnels)
// Exemple : /api/equipements?type=ordinateur&statut=Disponible
router.get('/', verifyToken, equipementsController.getAll);
 
// GET /api/equipements/stats → Statistiques des équipements
router.get('/stats', verifyToken, requireRole('admin', 'enseignant'), equipementsController.getStats);
 
// GET /api/equipements/:id → Détail d'un équipement
router.get('/:id', verifyToken, equipementsController.getById);
 
// ─── Routes admin seulement ───────────────────────────────────────────────────
 
// POST /api/equipements → Créer un équipement
router.post('/', verifyToken, requireRole('admin'), equipementsController.create);
 
// PUT /api/equipements/:id → Modifier un équipement
router.put('/:id', verifyToken, requireRole('admin'), equipementsController.update);
 
// PATCH /api/equipements/:id/statut → Changer uniquement le statut
router.patch('/:id/statut', verifyToken, requireRole('admin'), equipementsController.updateStatut);
 
// DELETE /api/equipements/:id → Supprimer un équipement
router.delete('/:id', verifyToken, requireRole('admin'), equipementsController.remove);
 
module.exports = router;
 