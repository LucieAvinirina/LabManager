const express = require('express');
const router = express.Router();
const notificationsController = require('./notifications.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');
const { requireRole } = require('../../middlewares/role.middleware');
 
// POST /api/notifications/all → Envoyer à tous les utilisateurs (admin)
router.post('/all', verifyToken, requireRole('admin'), notificationsController.sendToAll);
 
// POST /api/notifications/user → Envoyer à un utilisateur précis (admin)
router.post('/user', verifyToken, requireRole('admin'), notificationsController.sendToUser);
 
module.exports = router;
 