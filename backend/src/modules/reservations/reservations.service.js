const pool = require('../../config/db');
const notificationsService = require('../notifications/notifications.service');

 
// ─── Vérification de conflit de réservation ───────────────────────────────────
// Règle R1 : Un équipement ne peut pas avoir deux réservations qui se chevauchent
const verifierConflits = async (ids_equipements, date_debut, date_fin, exclude_id = null) => {
  const conflicts = [];
 
  for (const id_equipement of ids_equipements) {
    let query = `
      SELECT r.id_reservation, r.date_heure_debut, r.date_heure_fin, u.nom, u.prenom
      FROM reservations r
      JOIN details_reservation dr ON r.id_reservation = dr.id_reservation
      JOIN utilisateurs u ON r.id_utilisateur = u.id_utilisateur
      WHERE dr.id_equipement = $1
        AND r.statut IN ('En attente', 'Confirmée')
        AND (
          ($2 < r.date_heure_fin AND $3 > r.date_heure_debut)
        )
    `;
    const params = [id_equipement, date_debut, date_fin];
 
    if (exclude_id) {
      query += ` AND r.id_reservation != $4`;
      params.push(exclude_id);
    }
 
    const result = await pool.query(query, params);
    if (result.rows.length > 0) {
      conflicts.push({ id_equipement, conflits: result.rows });
    }
  }
 
  return conflicts;
};
 
// ─── Lister toutes les réservations ──────────────────────────────────────────
const getAll = async (filters = {}, user) => {
  let query = `
    SELECT 
      r.id_reservation,
      r.date_heure_debut,
      r.date_heure_fin,
      r.statut,
      r.type_reservation,
      r.est_recurrente,
      r.frequence,
      r.motif,
      r.date_creation,
      u.id_utilisateur,
      u.nom,
      u.prenom,
      u.email,
      u.role,
      COALESCE(
        json_agg(
          json_build_object(
            'id_equipement', e.id_equipement,
            'nom', e.nom,
            'type', e.type,
            'statut', e.statut
          )
        ) FILTER (WHERE e.id_equipement IS NOT NULL),
        '[]'
      ) AS equipements
    FROM reservations r
    JOIN utilisateurs u ON r.id_utilisateur = u.id_utilisateur
    LEFT JOIN details_reservation dr ON r.id_reservation = dr.id_reservation
    LEFT JOIN equipements e ON dr.id_equipement = e.id_equipement
    WHERE 1=1
  `;
 
  const params = [];
  let paramIndex = 1;
 
  // Un étudiant ou enseignant ne voit que ses propres réservations
  if (user.role === 'etudiant' || user.role === 'enseignant') {
    query += ` AND r.id_utilisateur = $${paramIndex++}`;
    params.push(user.id);
  }
 
  // Filtre par statut
  if (filters.statut) {
    query += ` AND r.statut = $${paramIndex++}`;
    params.push(filters.statut);
  }
 
  // Filtre par date
  if (filters.date) {
    query += ` AND DATE(r.date_heure_debut) = $${paramIndex++}`;
    params.push(filters.date);
  }
 
  query += ` GROUP BY r.id_reservation, u.id_utilisateur ORDER BY r.date_heure_debut DESC`;
 
  const result = await pool.query(query, params);
  return result.rows;
};
 
// ─── Obtenir une réservation par ID ──────────────────────────────────────────
const getById = async (id, user) => {
  const result = await pool.query(`
    SELECT 
      r.*,
      u.nom, u.prenom, u.email, u.role,
      COALESCE(
        json_agg(
          json_build_object(
            'id_equipement', e.id_equipement,
            'nom', e.nom,
            'type', e.type,
            'statut', e.statut
          )
        ) FILTER (WHERE e.id_equipement IS NOT NULL),
        '[]'
      ) AS equipements
    FROM reservations r
    JOIN utilisateurs u ON r.id_utilisateur = u.id_utilisateur
    LEFT JOIN details_reservation dr ON r.id_reservation = dr.id_reservation
    LEFT JOIN equipements e ON dr.id_equipement = e.id_equipement
    WHERE r.id_reservation = $1
    GROUP BY r.id_reservation, u.id_utilisateur, u.nom, u.prenom, u.email, u.role
  `, [id]);
 
  if (result.rows.length === 0) {
    throw new Error('RESERVATION_NOT_FOUND');
  }
 
  const reservation = result.rows[0];
 
  // Un étudiant ou enseignant ne peut voir que ses propres réservations
  if ((user.role === 'etudiant' || user.role === 'enseignant') && reservation.id_utilisateur !== user.id) {
    throw new Error('ACCES_REFUSE');
  }
 
  return reservation;
};
 
// ─── Créer une réservation ────────────────────────────────────────────────────
const create = async ({
  id_utilisateur,
  ids_equipements,
  date_heure_debut,
  date_heure_fin,
  type_reservation,
  est_recurrente,
  frequence,
  motif,
  role,
}) => {
 
  // Règle R6 : Si type = salle_entiere → réserver TOUS les ordinateurs
  if (type_reservation === 'salle_entiere') {
    if (role !== 'enseignant' && role !== 'admin') {
      throw new Error('PERMISSION_DENIED_SALLE');
    }
    const ordinateurs = await pool.query(
      `SELECT id_equipement FROM equipements 
       WHERE type = 'ordinateur' AND statut != 'Hors service'`
    );
    ids_equipements = ordinateurs.rows.map(r => r.id_equipement);
  }
 
  if (!ids_equipements || ids_equipements.length === 0) {
    throw new Error('AUCUN_EQUIPEMENT');
  }
 
  // Vérifier que les équipements existent et sont disponibles
  for (const id of ids_equipements) {
    const eq = await pool.query(
      'SELECT statut FROM equipements WHERE id_equipement = $1',
      [id]
    );
    if (eq.rows.length === 0) throw new Error(`EQUIPEMENT_NOT_FOUND:${id}`);
 
    // Règle R5 : Équipement en panne ou maintenance → non réservable
    if (['En panne', 'Hors service', 'En maintenance'].includes(eq.rows[0].statut)) {
      throw new Error(`EQUIPEMENT_INDISPONIBLE:${id}`);
    }
  }
 
  // Règle R1 : Vérification des conflits
  const conflits = await verifierConflits(ids_equipements, date_heure_debut, date_heure_fin);
  if (conflits.length > 0) {
    throw new Error(`CONFLIT_RESERVATION:${JSON.stringify(conflits)}`);
  }
 
  // Créer la réservation dans une transaction
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
 
    // Insérer la réservation
    const resResult = await client.query(
      `INSERT INTO reservations 
        (id_utilisateur, date_heure_debut, date_heure_fin, statut, type_reservation, est_recurrente, frequence, motif)
       VALUES ($1, $2, $3, 'En attente', $4, $5, $6, $7)
       RETURNING *`,
      [
        id_utilisateur,
        date_heure_debut,
        date_heure_fin,
        type_reservation || 'poste',
        est_recurrente || false,
        frequence || null,
        motif || null,
      ]
    );
 
    const reservation = resResult.rows[0];
 
    // Insérer les détails (équipements liés)
    for (const id_equipement of ids_equipements) {
      await client.query(
        `INSERT INTO details_reservation (id_reservation, id_equipement) VALUES ($1, $2)`,
        [reservation.id_reservation, id_equipement]
      );
    }
 
    await client.query('COMMIT');
    return reservation;
 
  } catch (error) {
    await client.query('ROLLBACK');
    throw error;
  } finally {
    client.release();
  }
};
 
// ─── Valider ou refuser une réservation (admin) ───────────────────────────────
// Règle R2 : Seul l'admin peut confirmer ou refuser
const valider = async (id, statut, admin_id) => {
  const statutsValides = ['Confirmée', 'Annulée'];
  if (!statutsValides.includes(statut)) {
    throw new Error('STATUT_INVALIDE');
  }
 
  const result = await pool.query(
    `SELECT * FROM reservations WHERE id_reservation = $1`,
    [id]
  );
 
  if (result.rows.length === 0) throw new Error('RESERVATION_NOT_FOUND');
 
  const reservation = result.rows[0];
  if (reservation.statut !== 'En attente') {
    throw new Error('RESERVATION_DEJA_TRAITEE');
  }
 
  // Mettre à jour le statut
  const updated = await pool.query(
    `UPDATE reservations SET statut = $1 WHERE id_reservation = $2 RETURNING *`,
    [statut, id]
  );
   // 🔔 Notification
  await notificationsService.notifierStatutReservation(id, statut);
 
  // Règle R3 : Si confirmée → équipements passent en "En cours d'utilisation"
  if (statut === 'Confirmée') {
    await pool.query(`
      UPDATE equipements SET statut = 'En cours d''utilisation'
      WHERE id_equipement IN (
        SELECT id_equipement FROM details_reservation WHERE id_reservation = $1
      )
    `, [id]);
  }
 
  return updated.rows[0];
};
 
// ─── Annuler une réservation ──────────────────────────────────────────────────
// Règle R7 : Un utilisateur ne peut annuler que sa propre réservation
const annuler = async (id, user) => {
  const result = await pool.query(
    `SELECT * FROM reservations WHERE id_reservation = $1`,
    [id]
  );
 
  if (result.rows.length === 0) throw new Error('RESERVATION_NOT_FOUND');
 
  const reservation = result.rows[0];
 
  // Vérifier que c'est bien sa réservation (sauf admin)
  if (user.role !== 'admin' && reservation.id_utilisateur !== user.id) {
    throw new Error('ACCES_REFUSE');
  }
 
  if (['Annulée', 'Terminée'].includes(reservation.statut)) {
    throw new Error('RESERVATION_DEJA_TRAITEE');
  }
 
  await pool.query(
    `UPDATE reservations SET statut = 'Annulée' WHERE id_reservation = $1`,
    [id]
  );
 
  // Remettre les équipements en Disponible si la réservation était confirmée
  if (reservation.statut === 'Confirmée') {
    await pool.query(`
      UPDATE equipements SET statut = 'Disponible'
      WHERE id_equipement IN (
        SELECT id_equipement FROM details_reservation WHERE id_reservation = $1
      )
    `, [id]);
  }
 
  return { message: 'Réservation annulée avec succès' };
};
 
// ─── Historique des réservations d'un utilisateur ────────────────────────────
const getHistorique = async (id_utilisateur) => {
  const result = await pool.query(`
    SELECT r.id_reservation, r.date_heure_debut, r.date_heure_fin,
           r.statut, r.type_reservation, r.date_creation,
           COALESCE(
             json_agg(json_build_object('nom', e.nom, 'type', e.type))
             FILTER (WHERE e.id_equipement IS NOT NULL), '[]'
           ) AS equipements
    FROM reservations r
    LEFT JOIN details_reservation dr ON r.id_reservation = dr.id_reservation
    LEFT JOIN equipements e ON dr.id_equipement = e.id_equipement
    WHERE r.id_utilisateur = $1
    GROUP BY r.id_reservation
    ORDER BY r.date_heure_debut DESC
  `, [id_utilisateur]);
 
  return result.rows;
};
 
module.exports = { getAll, getById, create, valider, annuler, getHistorique, verifierConflits };