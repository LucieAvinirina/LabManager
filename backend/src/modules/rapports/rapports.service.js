const pool = require('../../config/db');
 
// ─── Tableau de bord global (admin) ──────────────────────────────────────────
// Vue d'ensemble complète du laboratoire
const getDashboard = async () => {
 
  // Statistiques des réservations
  const reservations = await pool.query(`
    SELECT
      COUNT(*) FILTER (WHERE statut = 'En attente')  AS en_attente,
      COUNT(*) FILTER (WHERE statut = 'Confirmée')   AS confirmees,
      COUNT(*) FILTER (WHERE statut = 'Annulée')     AS annulees,
      COUNT(*) FILTER (WHERE statut = 'Terminée')    AS terminees,
      COUNT(*)                                        AS total
    FROM reservations
  `);
 
  // Statistiques des équipements
  const equipements = await pool.query(`
    SELECT
      COUNT(*) FILTER (WHERE statut = 'Disponible')               AS disponibles,
      COUNT(*) FILTER (WHERE statut = 'En cours d''utilisation')  AS en_utilisation,
      COUNT(*) FILTER (WHERE statut = 'En maintenance')           AS en_maintenance,
      COUNT(*) FILTER (WHERE statut = 'En panne')                 AS en_panne,
      COUNT(*) FILTER (WHERE statut = 'Hors service')             AS hors_service,
      COUNT(*)                                                     AS total
    FROM equipements
  `);
 
  // Statistiques des incidents
  const incidents = await pool.query(`
    SELECT
      COUNT(*) FILTER (WHERE statut = 'Nouveau')                AS nouveaux,
      COUNT(*) FILTER (WHERE statut = 'En cours de traitement') AS en_cours,
      COUNT(*) FILTER (WHERE statut = 'Résolu')                 AS resolus,
      COUNT(*) FILTER (WHERE statut = 'Clôturé')                AS clotures,
      COUNT(*)                                                   AS total
    FROM incidents
  `);
 
  // Statistiques des utilisateurs
  const utilisateurs = await pool.query(`
    SELECT
      COUNT(*) FILTER (WHERE role = 'etudiant')   AS etudiants,
      COUNT(*) FILTER (WHERE role = 'enseignant') AS enseignants,
      COUNT(*) FILTER (WHERE role = 'admin')      AS admins,
      COUNT(*)                                    AS total
    FROM utilisateurs
    WHERE est_actif = TRUE
  `);
 
  // Réservations du jour
  const reservations_aujourdhui = await pool.query(`
    SELECT COUNT(*) AS count
    FROM reservations
    WHERE DATE(date_heure_debut) = CURRENT_DATE
      AND statut = 'Confirmée'
  `);
 
  return {
    reservations:            reservations.rows[0],
    equipements:             equipements.rows[0],
    incidents:               incidents.rows[0],
    utilisateurs:            utilisateurs.rows[0],
    reservations_aujourdhui: reservations_aujourdhui.rows[0].count,
  };
};
 
// ─── Taux d'occupation par période ───────────────────────────────────────────
// Nombre de réservations confirmées par jour sur une période donnée
const getTauxOccupation = async (date_debut, date_fin) => {
  const result = await pool.query(`
    SELECT
      DATE(date_heure_debut)                    AS date,
      COUNT(*)                                  AS nb_reservations,
      COUNT(*) FILTER (WHERE type_reservation = 'salle_entiere') AS reservations_salle,
      COUNT(*) FILTER (WHERE type_reservation = 'poste')         AS reservations_poste
    FROM reservations
    WHERE statut = 'Confirmée'
      AND date_heure_debut >= $1
      AND date_heure_debut <= $2
    GROUP BY DATE(date_heure_debut)
    ORDER BY date ASC
  `, [date_debut, date_fin]);
 
  return result.rows;
};
 
// ─── Équipements les plus utilisés ───────────────────────────────────────────
const getEquipementsLesPlusUtilises = async (limite = 10) => {
  const result = await pool.query(`
    SELECT
      e.id_equipement,
      e.nom,
      e.type,
      e.statut,
      COUNT(dr.id_reservation) AS nb_reservations
    FROM equipements e
    LEFT JOIN details_reservation dr ON e.id_equipement = dr.id_equipement
    LEFT JOIN reservations r ON dr.id_reservation = r.id_reservation
      AND r.statut IN ('Confirmée', 'Terminée')
    GROUP BY e.id_equipement, e.nom, e.type, e.statut
    ORDER BY nb_reservations DESC
    LIMIT $1
  `, [limite]);
 
  return result.rows;
};
 
// ─── Équipements les plus en panne ───────────────────────────────────────────
const getEquipementsLesPlusDefaillants = async (limite = 10) => {
  const result = await pool.query(`
    SELECT
      e.id_equipement,
      e.nom,
      e.type,
      e.statut,
      COUNT(i.id_incident) AS nb_incidents,
      MAX(i.date_heure_signalement) AS dernier_incident
    FROM equipements e
    LEFT JOIN incidents i ON e.id_equipement = i.id_equipement
    GROUP BY e.id_equipement, e.nom, e.type, e.statut
    ORDER BY nb_incidents DESC
    LIMIT $1
  `, [limite]);
 
  return result.rows;
};
 
// ─── Réservations par utilisateur ────────────────────────────────────────────
const getReservationsParUtilisateur = async () => {
  const result = await pool.query(`
    SELECT
      u.id_utilisateur,
      u.nom,
      u.prenom,
      u.role,
      COUNT(r.id_reservation)                                      AS total,
      COUNT(*) FILTER (WHERE r.statut = 'Confirmée')               AS confirmees,
      COUNT(*) FILTER (WHERE r.statut = 'Annulée')                 AS annulees,
      COUNT(*) FILTER (WHERE r.type_reservation = 'salle_entiere') AS salles_entieres
    FROM utilisateurs u
    LEFT JOIN reservations r ON u.id_utilisateur = r.id_utilisateur
    WHERE u.est_actif = TRUE
    GROUP BY u.id_utilisateur, u.nom, u.prenom, u.role
    ORDER BY total DESC
  `);
 
  return result.rows;
};
 
// ─── Statistiques personnelles (enseignant) ───────────────────────────────────
const getStatsPersonnelles = async (id_utilisateur) => {
  const reservations = await pool.query(`
    SELECT
      COUNT(*)                                          AS total,
      COUNT(*) FILTER (WHERE statut = 'Confirmée')     AS confirmees,
      COUNT(*) FILTER (WHERE statut = 'Annulée')       AS annulees,
      COUNT(*) FILTER (WHERE statut = 'En attente')    AS en_attente,
      COUNT(*) FILTER (WHERE est_recurrente = TRUE)    AS recurrentes
    FROM reservations
    WHERE id_utilisateur = $1
  `, [id_utilisateur]);
 
  const incidents = await pool.query(`
    SELECT COUNT(*) AS total
    FROM incidents
    WHERE id_utilisateur = $1
  `, [id_utilisateur]);
 
  const prochaines = await pool.query(`
    SELECT 
      r.id_reservation, r.date_heure_debut, r.date_heure_fin,
      r.type_reservation, r.statut,
      COALESCE(
        json_agg(json_build_object('nom', e.nom, 'type', e.type))
        FILTER (WHERE e.id_equipement IS NOT NULL), '[]'
      ) AS equipements
    FROM reservations r
    LEFT JOIN details_reservation dr ON r.id_reservation = dr.id_reservation
    LEFT JOIN equipements e ON dr.id_equipement = e.id_equipement
    WHERE r.id_utilisateur = $1
      AND r.date_heure_debut > NOW()
      AND r.statut = 'Confirmée'
    GROUP BY r.id_reservation
    ORDER BY r.date_heure_debut ASC
    LIMIT 5
  `, [id_utilisateur]);
 
  return {
    reservations:        reservations.rows[0],
    incidents_signales:  incidents.rows[0].total,
    prochaines_seances:  prochaines.rows,
  };
};
 
// ─── Export CSV des réservations ─────────────────────────────────────────────
const getReservationsCSV = async (date_debut, date_fin) => {
  const result = await pool.query(`
    SELECT
      r.id_reservation,
      u.nom || ' ' || u.prenom AS utilisateur,
      u.role,
      r.date_heure_debut,
      r.date_heure_fin,
      r.type_reservation,
      r.statut,
      r.motif,
      r.date_creation
    FROM reservations r
    JOIN utilisateurs u ON r.id_utilisateur = u.id_utilisateur
    WHERE r.date_heure_debut >= $1
      AND r.date_heure_debut <= $2
    ORDER BY r.date_heure_debut ASC
  `, [date_debut, date_fin]);
 
  return result.rows;
};
 
module.exports = {
  getDashboard,
  getTauxOccupation,
  getEquipementsLesPlusUtilises,
  getEquipementsLesPlusDefaillants,
  getReservationsParUtilisateur,
  getStatsPersonnelles,
  getReservationsCSV,
};