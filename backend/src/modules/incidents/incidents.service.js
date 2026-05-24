
const pool = require('../../config/db');
const notificationsService = require('../notifications/notifications.service');
 
// ─── Lister tous les incidents ────────────────────────────────────────────────
const getAll = async (filters = {}, user) => {
  let query = `
    SELECT 
      i.id_incident,
      i.description,
      i.date_heure_signalement,
      i.statut,
      i.photo_url,
      i.date_resolution,
      e.id_equipement,
      e.nom  AS equipement_nom,
      e.type AS equipement_type,
      u.id_utilisateur,
      u.nom  AS signale_par_nom,
      u.prenom AS signale_par_prenom,
      u.role AS signale_par_role
    FROM incidents i
    JOIN equipements e ON i.id_equipement = e.id_equipement
    JOIN utilisateurs u ON i.id_utilisateur = u.id_utilisateur
    WHERE 1=1
  `;
 
  const params = [];
  let paramIndex = 1;
 
  // Un étudiant ne voit que ses propres incidents
  if (user.role === 'etudiant') {
    query += ` AND i.id_utilisateur = $${paramIndex++}`;
    params.push(user.id);
  }
 
  // Filtre par statut
  if (filters.statut) {
    query += ` AND i.statut = $${paramIndex++}`;
    params.push(filters.statut);
  }
 
  // Filtre par équipement
  if (filters.id_equipement) {
    query += ` AND i.id_equipement = $${paramIndex++}`;
    params.push(filters.id_equipement);
  }
 
  query += ' ORDER BY i.date_heure_signalement DESC';
 
  const result = await pool.query(query, params);
  return result.rows;
};
 
// ─── Obtenir un incident par ID ───────────────────────────────────────────────
const getById = async (id, user) => {
  const result = await pool.query(`
    SELECT 
      i.*,
      e.nom  AS equipement_nom,
      e.type AS equipement_type,
      u.nom  AS signale_par_nom,
      u.prenom AS signale_par_prenom
    FROM incidents i
    JOIN equipements e ON i.id_equipement = e.id_equipement
    JOIN utilisateurs u ON i.id_utilisateur = u.id_utilisateur
    WHERE i.id_incident = $1
  `, [id]);
 
  if (result.rows.length === 0) {
    throw new Error('INCIDENT_NOT_FOUND');
  }
 
  const incident = result.rows[0];
 
  // Un étudiant ne voit que ses propres incidents
  if (user.role === 'etudiant' && incident.id_utilisateur !== user.id) {
    throw new Error('ACCES_REFUSE');
  }
 
  return incident;
};
 
// ─── Signaler un incident ─────────────────────────────────────────────────────
// Règle R4 : Quand un incident est créé → équipement passe en "En panne"
const create = async ({ id_equipement, id_utilisateur, description, photo_url }) => {
 
  // Vérifier que l'équipement existe
  const eq = await pool.query(
    'SELECT id_equipement, statut FROM equipements WHERE id_equipement = $1',
    [id_equipement]
  );
 
  if (eq.rows.length === 0) {
    throw new Error('EQUIPEMENT_NOT_FOUND');
  }
 
  // Vérifier que l'équipement n'est pas déjà hors service
  if (eq.rows[0].statut === 'Hors service') {
    throw new Error('EQUIPEMENT_HORS_SERVICE');
  }
 
  // Transaction : créer l'incident + mettre équipement en panne
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
 
    // Créer l'incident
    const result = await client.query(`
      INSERT INTO incidents (id_equipement, id_utilisateur, description, photo_url)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [id_equipement, id_utilisateur, description, photo_url || null]);
 
    // Règle R4 : Mettre l'équipement en panne automatiquement
    await client.query(`
      UPDATE equipements SET statut = 'En panne'
      WHERE id_equipement = $1
    `, [id_equipement]);
 
    await client.query('COMMIT');
    // 🔔 Notification après création incident
await notificationsService.notifierNouvelIncident(
  result.rows[0].id_incident,
  eq.rows[0].nom
);
    return result.rows[0];
 
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};
 
// ─── Mettre à jour le statut d'un incident (admin seulement) ─────────────────
const updateStatut = async (id, statut, admin_id) => {
  const statutsValides = ['Nouveau', 'En cours de traitement', 'Résolu', 'Clôturé'];
 
  if (!statutsValides.includes(statut)) {
    throw new Error('STATUT_INVALIDE');
  }
 
  // Vérifier que l'incident existe
  const incident = await pool.query(
    'SELECT * FROM incidents WHERE id_incident = $1',
    [id]
  );
 
  if (incident.rows.length === 0) {
    throw new Error('INCIDENT_NOT_FOUND');
  }
 
  // Si résolu ou clôturé → remettre l'équipement en Disponible
  // et enregistrer la date de résolution
  let query;
  let params;
 
  if (['Résolu', 'Clôturé'].includes(statut)) {
    query = `
      UPDATE incidents 
      SET statut = $1, date_resolution = NOW()
      WHERE id_incident = $2
      RETURNING *
    `;
    params = [statut, id];
 
    // Remettre l'équipement en Disponible
    await pool.query(`
      UPDATE equipements SET statut = 'Disponible'
      WHERE id_equipement = $1
    `, [incident.rows[0].id_equipement]);
 
  } else {
    query = `UPDATE incidents SET statut = $1 WHERE id_incident = $2 RETURNING *`;
    params = [statut, id];
  }
 
  const result = await pool.query(query, params);
  return result.rows[0];
};
 
// ─── Statistiques des incidents ───────────────────────────────────────────────
const getStats = async () => {
  const result = await pool.query(`
    SELECT
      COUNT(*) FILTER (WHERE statut = 'Nouveau')               AS nouveaux,
      COUNT(*) FILTER (WHERE statut = 'En cours de traitement') AS en_cours,
      COUNT(*) FILTER (WHERE statut = 'Résolu')                AS resolus,
      COUNT(*) FILTER (WHERE statut = 'Clôturé')               AS clotures,
      COUNT(*)                                                  AS total,
      AVG(
        EXTRACT(EPOCH FROM (date_resolution - date_heure_signalement))/3600
      ) FILTER (WHERE date_resolution IS NOT NULL)             AS delai_moyen_heures
    FROM incidents
  `);
 
  return result.rows[0];
};
 
// ─── Incidents par équipement (pour identifier les équipements défaillants) ───
const getByEquipement = async (id_equipement) => {
  const result = await pool.query(`
    SELECT 
      i.id_incident, i.description, i.statut,
      i.date_heure_signalement, i.date_resolution,
      u.nom, u.prenom
    FROM incidents i
    JOIN utilisateurs u ON i.id_utilisateur = u.id_utilisateur
    WHERE i.id_equipement = $1
    ORDER BY i.date_heure_signalement DESC
  `, [id_equipement]);
 
  return result.rows;
};
 
module.exports = { getAll, getById, create, updateStatut, getStats, getByEquipement };