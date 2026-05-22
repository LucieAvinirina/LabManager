// ─── Vérification du rôle utilisateur ────────────────────────────────────────
// Ce middleware s'utilise APRÈS verifyToken
// Il vérifie que l'utilisateur connecté a le bon rôle pour accéder à la route
//
// Exemple d'utilisation dans une route :
//   router.delete('/:id', verifyToken, requireRole('admin'), controller.delete)
//   router.get('/stats', verifyToken, requireRole('admin', 'enseignant'), controller.stats)
 
const requireRole = (...rolesAutorises) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Non authentifié',
      });
    }
 
    if (!rolesAutorises.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Accès refusé. Rôle requis : ${rolesAutorises.join(' ou ')}`,
      });
    }
 
    next();
  };
};
 
module.exports = { requireRole };
 