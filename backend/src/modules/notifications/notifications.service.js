
const admin = require('../../config/firebase');
const pool = require('../../config/db');
 
// ─── Envoyer une notification à UN utilisateur ────────────────────────────────
// Utilisé pour : confirmation/refus de réservation, rappel avant séance
const sendToUser = async (id_utilisateur, { title, body, data = {} }) => {
 
  // Récupérer le FCM token de l'utilisateur
  const result = await pool.query(
    'SELECT fcm_token, nom, prenom FROM utilisateurs WHERE id_utilisateur = $1',
    [id_utilisateur]
  );
 
  if (result.rows.length === 0) {
    throw new Error('UTILISATEUR_NOT_FOUND');
  }
 
  const { fcm_token, nom, prenom } = result.rows[0];
 
  // Si l'utilisateur n'a pas de token FCM → pas de notification push
  if (!fcm_token) {
    console.log(`Pas de FCM token pour ${prenom} ${nom} — notification ignorée`);
    return { success: false, reason: 'NO_FCM_TOKEN' };
  }
 
  // Construire le message Firebase
  const message = {
    token: fcm_token,
    notification: {
      title,
      body,
    },
    data: {
      ...data,
      // Convertir toutes les valeurs en string (requis par Firebase)
      timestamp: new Date().toISOString(),
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
  };
 
  try {
    const response = await admin.messaging().send(message);
    console.log(`Notification envoyée à ${prenom} ${nom} :`, response);
    return { success: true, messageId: response };
  } catch (error) {
    console.error(` Erreur envoi notification à ${prenom} ${nom} :`, error.message);
    return { success: false, error: error.message };
  }
};
 
// ─── Envoyer une notification à TOUS les utilisateurs ─────────────────────────
// Utilisé pour : fermeture exceptionnelle, annonce générale (admin)
const sendToAll = async ({ title, body, data = {} }) => {
 
  // Récupérer tous les FCM tokens actifs
  const result = await pool.query(
    `SELECT fcm_token, nom, prenom 
     FROM utilisateurs 
     WHERE fcm_token IS NOT NULL AND est_actif = TRUE`
  );
 
  if (result.rows.length === 0) {
    return { success: false, reason: 'NO_USERS_WITH_TOKEN', count: 0 };
  }
 
  const tokens = result.rows.map(u => u.fcm_token);
 
  // Envoyer en multicast (jusqu'à 500 tokens par batch)
  const message = {
    tokens,
    notification: { title, body },
    data: {
      ...data,
      timestamp: new Date().toISOString(),
    },
    android: {
      priority: 'high',
      notification: {
        sound: 'default',
        clickAction: 'FLUTTER_NOTIFICATION_CLICK',
      },
    },
    apns: {
      payload: {
        aps: { sound: 'default', badge: 1 },
      },
    },
  };
 
  try {
    const response = await admin.messaging().sendEachForMulticast(message);
    console.log(` Notification envoyée à ${response.successCount} utilisateurs`);
    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    console.error(' Erreur envoi notification multicast :', error.message);
    return { success: false, error: error.message };
  }
};
 
// ─── Notification : Réservation confirmée ou refusée ─────────────────────────
// Règle R8 : Une notification push est envoyée quand une réservation est traitée
const notifierStatutReservation = async (id_reservation, statut) => {
 
  const result = await pool.query(`
    SELECT r.id_utilisateur, r.date_heure_debut, r.date_heure_fin
    FROM reservations r
    WHERE r.id_reservation = $1
  `, [id_reservation]);
 
  if (result.rows.length === 0) return;
 
  const { id_utilisateur, date_heure_debut } = result.rows[0];
  const dateFormatee = new Date(date_heure_debut).toLocaleString('fr-FR');
 
  let title, body;
 
  if (statut === 'Confirmée') {
    title = ' Réservation confirmée';
    body  = `Votre réservation du ${dateFormatee} a été confirmée.`;
  } else if (statut === 'Annulée') {
    title = ' Réservation annulée';
    body  = `Votre réservation du ${dateFormatee} a été annulée par l'administrateur.`;
  } else {
    return;
  }
 
  await sendToUser(id_utilisateur, {
    title,
    body,
    data: {
      type:           'reservation',
      id_reservation: String(id_reservation),
      statut,
    },
  });
};
 
// ─── Notification : Rappel avant une réservation ─────────────────────────────
const notifierRappelReservation = async (id_reservation, minutes_avant = 30) => {
 
  const result = await pool.query(`
    SELECT r.id_utilisateur, r.date_heure_debut
    FROM reservations r
    WHERE r.id_reservation = $1 AND r.statut = 'Confirmée'
  `, [id_reservation]);
 
  if (result.rows.length === 0) return;
 
  const { id_utilisateur, date_heure_debut } = result.rows[0];
  const dateFormatee = new Date(date_heure_debut).toLocaleString('fr-FR');
 
  await sendToUser(id_utilisateur, {
    title: ' Rappel de réservation',
    body:  `Votre séance commence dans ${minutes_avant} minutes (${dateFormatee})`,
    data: {
      type:           'rappel',
      id_reservation: String(id_reservation),
    },
  });
};
 
// ─── Notification : Incident signalé (notifier l'admin) ──────────────────────
const notifierNouvelIncident = async (id_incident, equipement_nom) => {
 
  // Récupérer tous les admins
  const admins = await pool.query(
    `SELECT id_utilisateur FROM utilisateurs WHERE role = 'admin' AND est_actif = TRUE`
  );
 
  for (const admin of admins.rows) {
    await sendToUser(admin.id_utilisateur, {
      title: '🔧 Nouvel incident signalé',
      body:  `Un incident a été signalé sur ${equipement_nom}. Veuillez intervenir.`,
      data: {
        type:        'incident',
        id_incident: String(id_incident),
      },
    });
  }
};
 
module.exports = {
  sendToUser,
  sendToAll,
  notifierStatutReservation,
  notifierRappelReservation,
  notifierNouvelIncident,
};