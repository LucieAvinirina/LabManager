
const pool = require('../../config/db');
const bcrypt = require('bcryptjs');
 
// ─── Lister tous les utilisateurs (admin seulement) ──────────────────────────
const getAll = async (filters = {}) => {
  let query = `
    SELECT 
      id_utilisateur, nom, prenom, email, 
      role, date_creation, est_actif, fcm_token
    FROM utilisateurs
    WHERE 1=1
  `;
  const params = [];
  let paramIndex = 1;
 
  // Filtre par rôle
  if (filters.role) {
    query += ` AND role = $${paramIndex++}`;
    params.push(filters.role);
  }
 
  // Filtre par statut actif/inactif
  if (filters.est_actif !== undefined) {
    query += ` AND est_actif = $${paramIndex++}`;
    params.push(filters.est_actif);
  }
 
  query += ' ORDER BY date_creation DESC';
 
  const result = await pool.query(query, params);
  return result.rows;
};
 
// ─── Obtenir un utilisateur par ID ───────────────────────────────────────────
const getById = async (id) => {
  const result = await pool.query(`
    SELECT id_utilisateur, nom, prenom, email, role, date_creation, est_actif
    FROM utilisateurs
    WHERE id_utilisateur = $1
  `, [id]);
 
  if (result.rows.length === 0) {
    throw new Error('USER_NOT_FOUND');
  }
 
  return result.rows[0];
};
 
// ─── Obtenir le profil de l'utilisateur connecté ─────────────────────────────
const getProfile = async (id) => {
  const result = await pool.query(`
    SELECT 
      u.id_utilisateur, u.nom, u.prenom, u.email, 
      u.role, u.date_creation,
      COUNT(DISTINCT r.id_reservation) AS total_reservations,
      COUNT(DISTINCT i.id_incident)    AS total_incidents
    FROM utilisateurs u
    LEFT JOIN reservations r ON u.id_utilisateur = r.id_utilisateur
    LEFT JOIN incidents i    ON u.id_utilisateur = i.id_utilisateur
    WHERE u.id_utilisateur = $1
    GROUP BY u.id_utilisateur
  `, [id]);
 
  if (result.rows.length === 0) {
    throw new Error('USER_NOT_FOUND');
  }
 
  return result.rows[0];
};
 
// ─── Modifier un utilisateur (admin) ─────────────────────────────────────────
const update = async (id, { nom, prenom, email, role }) => {
  // Vérifier que l'utilisateur existe
  await getById(id);
 
  // Vérifier si le nouvel email est déjà pris par quelqu'un d'autre
  if (email) {
    const existing = await pool.query(
      'SELECT id_utilisateur FROM utilisateurs WHERE email = $1 AND id_utilisateur != $2',
      [email, id]
    );
    if (existing.rows.length > 0) {
      throw new Error('EMAIL_ALREADY_EXISTS');
    }
  }
 
  const result = await pool.query(`
    UPDATE utilisateurs
    SET nom    = COALESCE($1, nom),
        prenom = COALESCE($2, prenom),
        email  = COALESCE($3, email),
        role   = COALESCE($4, role)
    WHERE id_utilisateur = $5
    RETURNING id_utilisateur, nom, prenom, email, role, date_creation, est_actif
  `, [nom, prenom, email, role, id]);
 
  return result.rows[0];
};
 
// ─── Modifier son propre profil ───────────────────────────────────────────────
const updateProfile = async (id, { nom, prenom }) => {
  const result = await pool.query(`
    UPDATE utilisateurs
    SET nom    = COALESCE($1, nom),
        prenom = COALESCE($2, prenom)
    WHERE id_utilisateur = $3
    RETURNING id_utilisateur, nom, prenom, email, role
  `, [nom, prenom, id]);
 
  return result.rows[0];
};
 
// ─── Changer son propre mot de passe ─────────────────────────────────────────
const changePassword = async (id, { ancien_mot_de_passe, nouveau_mot_de_passe }) => {
  // Récupérer le hash actuel
  const result = await pool.query(
    'SELECT mot_de_passe_hash FROM utilisateurs WHERE id_utilisateur = $1',
    [id]
  );
 
  if (result.rows.length === 0) throw new Error('USER_NOT_FOUND');
 
  // Vérifier l'ancien mot de passe
  const valide = await bcrypt.compare(ancien_mot_de_passe, result.rows[0].mot_de_passe_hash);
  if (!valide) throw new Error('ANCIEN_MDP_INVALIDE');
 
  // Valider le nouveau mot de passe
  if (nouveau_mot_de_passe.length < 6) {
    throw new Error('MDP_TROP_COURT');
  }
 
  // Hacher et enregistrer le nouveau mot de passe
  const hash = await bcrypt.hash(nouveau_mot_de_passe, 10);
  await pool.query(
    'UPDATE utilisateurs SET mot_de_passe_hash = $1 WHERE id_utilisateur = $2',
    [hash, id]
  );
};
 
// ─── Activer ou désactiver un compte (admin) ──────────────────────────────────
const toggleActif = async (id, est_actif) => {
  await getById(id);
 
  const result = await pool.query(`
    UPDATE utilisateurs SET est_actif = $1
    WHERE id_utilisateur = $2
    RETURNING id_utilisateur, nom, prenom, email, role, est_actif
  `, [est_actif, id]);
 
  return result.rows[0];
};
 
// ─── Supprimer un compte (admin) ──────────────────────────────────────────────
const remove = async (id) => {
  await getById(id);
 
  await pool.query(
    'DELETE FROM utilisateurs WHERE id_utilisateur = $1',
    [id]
  );
};
 
// ─── Statistiques des utilisateurs (admin) ────────────────────────────────────
const getStats = async () => {
  const result = await pool.query(`
    SELECT
      COUNT(*) FILTER (WHERE role = 'etudiant')    AS etudiants,
      COUNT(*) FILTER (WHERE role = 'enseignant')  AS enseignants,
      COUNT(*) FILTER (WHERE role = 'admin')       AS admins,
      COUNT(*) FILTER (WHERE est_actif = TRUE)     AS actifs,
      COUNT(*) FILTER (WHERE est_actif = FALSE)    AS inactifs,
      COUNT(*)                                     AS total
    FROM utilisateurs
  `);
 
  return result.rows[0];
};
 
module.exports = {
  getAll, getById, getProfile, update, updateProfile,
  changePassword, toggleActif, remove, getStats,
};