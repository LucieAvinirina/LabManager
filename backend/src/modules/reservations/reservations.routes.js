const express = require('express');
const router  = express.Router();
const reservationsController = require('./reservations.controller');
const { verifyToken }  = require('../../middlewares/auth.middleware');
const { requireRole }  = require('../../middlewares/role.middleware');
 
// GET /api/reservations → Liste des réservations
// Admin voit tout, étudiant/enseignant voient les leurs
router.get('/', verifyToken, reservationsController.getAll);
 
// GET /api/reservations/historique → Historique personnel
router.get('/historique', verifyToken, reservationsController.getHistorique);
 
// GET /api/reservations/:id → Détail d'une réservation
router.get('/:id', verifyToken, reservationsController.getById);
 
// POST /api/reservations → Créer une réservation
// Tous les rôles peuvent créer une réservation (etudiant, enseignant, admin)
router.post('/', verifyToken, requireRole('etudiant', 'enseignant', 'admin'), reservationsController.create);
 
// PATCH /api/reservations/:id/valider → Confirmer ou refuser (admin seulement)
router.patch('/:id/valider', verifyToken, requireRole('admin'), reservationsController.valider);
 
// PATCH /api/reservations/:id/annuler → Annuler une réservation
router.patch('/:id/annuler', verifyToken, reservationsController.annuler);
 
module.exports = router;