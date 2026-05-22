const express = require('express');
const router = express.Router();
const authController = require('./auth.controller');
const { verifyToken } = require('../../middlewares/auth.middleware');
 
// ─── Routes publiques (sans token) ───────────────────────────────────────────
// POST /api/auth/register → Créer un compte
router.post('/register', authController.register);
 
// POST /api/auth/login → Se connecter, reçoit un token JWT
router.post('/login', authController.login);
 
// ─── Routes protégées (token requis) ─────────────────────────────────────────
// PUT /api/auth/fcm-token → Mettre à jour le token de notification push
router.put('/fcm-token', verifyToken, authController.updateFcmToken);
 
module.exports = router;
 