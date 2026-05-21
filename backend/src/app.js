const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
require('dotenv').config();
 
const app = express();
 
// ─── Middlewares globaux ───────────────────────────────────────────────────────
app.use(helmet());         // Sécurité HTTP
app.use(cors());           // Autorise Flutter à appeler l'API
app.use(morgan('dev'));    // Log des requêtes dans le terminal
app.use(express.json());   // Parser le body JSON
 
// ─── Routes ───────────────────────────────────────────────────────────────────
app.use('/api/auth',         require('./modules/auth/auth.routes'));
app.use('/api/users',        require('./modules/users/users.routes'));
app.use('/api/equipements',  require('./modules/equipements/equipements.routes'));
app.use('/api/reservations', require('./modules/reservations/reservations.routes'));
app.use('/api/incidents',    require('./modules/incidents/incidents.routes'));
app.use('/api/rapports',     require('./modules/rapports/rapports.routes'));
 
// ─── Route de test ────────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.json({
    message: '✅ API LabManager opérationnelle',
    version: '1.0.0',
    endpoints: [
      '/api/auth',
      '/api/users',
      '/api/equipements',
      '/api/reservations',
      '/api/incidents',
      '/api/rapports',
    ],
  });
});
 
// ─── Gestion des routes inexistantes ──────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ message: '❌ Route non trouvée' });
});
 
// ─── Gestion globale des erreurs ──────────────────────────────────────────────
app.use((err, req, res, next) => {
  console.error('Erreur serveur :', err.message);
  res.status(500).json({ message: '❌ Erreur interne du serveur' });
});
 
module.exports = app;