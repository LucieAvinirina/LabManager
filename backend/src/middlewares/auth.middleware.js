const jwt = require('jsonwebtoken');
 
// ─── Vérification du token JWT ────────────────────────────────────────────────
// Ce middleware est placé devant toutes les routes protégées
// Il lit le token dans le header Authorization et vérifie sa validité
const verifyToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
 
  // Le header doit être de la forme : "Bearer <token>"
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      success: false,
      message: 'Accès refusé. Token manquant',
    });
  }
 
  const token = authHeader.split(' ')[1];
 
  try {
    // Vérifier et décoder le token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
 
    // Ajouter les infos de l'utilisateur dans req.user
    // pour que les controllers puissent y accéder
    req.user = {
      id:    decoded.id,
      email: decoded.email,
      role:  decoded.role,
    };
 
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        success: false,
        message: 'Token expiré. Veuillez vous reconnecter',
      });
    }
    return res.status(401).json({
      success: false,
      message: 'Token invalide',
    });
  }
};
 
module.exports = { verifyToken };