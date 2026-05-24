const admin = require('firebase-admin');
require('dotenv').config();
 
// ─── Initialisation Firebase Admin SDK ───────────────────────────────────────
// Ce fichier initialise la connexion à Firebase une seule fois
// et exporte l'objet admin pour être utilisé dans les services
 
let firebaseApp;
 
const initFirebase = () => {
  // Eviter d'initialiser plusieurs fois
  if (admin.apps.length > 0) {
    return admin.apps[0];
  }
 
  try {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId:   process.env.FIREBASE_PROJECT_ID,
        privateKey:  process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      }),
    });
 
    console.log(' Firebase Admin SDK initialisé');
    return firebaseApp;
 
  } catch (error) {
    console.error(' Erreur initialisation Firebase :', error.message);
    throw error;
  }
};
 
// Initialiser au démarrage
initFirebase();
 
module.exports = admin;
 