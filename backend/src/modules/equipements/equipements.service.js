
const pool = require('../../config/db');
 
// ─── Lister tous les équipements ─────────────────────────────────────────────
const getAll = async (filters = {}) => {
  let query = `
    SELECT id_equipement, nom, type, numero_serie, 
           date_acquisition, statut, description, date_creation
    FROM equipements
    WHERE 1=1
  `;
  const params = [];
  let paramIndex = 1;
 
  // Filtre par type (ex: ?type=ordinateur)
  if (filters.type) {
    query += ` AND type = $${paramIndex++}`;
    params.push(filters.type);
  }
 
  // Filtre par statut (ex: ?statut=Disponible)
  if (filters.statut) {
    query += ` AND statut = $${paramIndex++}`;
    params.push(filters.statut);
  }
 
  query += ' ORDER BY nom ASC';
 
  const result = await pool.query(query, params);
  return result.rows;
};
 
// ─── Obtenir un équipement par ID ─────────────────────────────────────────────
const getById = async (id) => {
  const result = await pool.query(
    `SELECT id_equipement, nom, type, numero_serie,
            date_acquisition, statut, description, date_creation
     FROM equipements
     WHERE id_equipement = $1`,
    [id]
  );
 
  if (result.rows.length === 0) {
    throw new Error('EQUIPEMENT_NOT_FOUND');
  }
 
  return result.rows[0];
};
 
// ─── Créer un équipement ──────────────────────────────────────────────────────
const create = async ({ nom, type, numero_serie, date_acquisition, statut, description }) => {
 
  // Vérifier si le numéro de série existe déjà
  if (numero_serie) {
    const existing = await pool.query(
      'SELECT id_equipement FROM equipements WHERE numero_serie = $1',
      [numero_serie]
    );
    if (existing.rows.length > 0) {
      throw new Error('NUMERO_SERIE_EXISTS');
    }
  }
 
  const result = await pool.query(
    `INSERT INTO equipements (nom, type, numero_serie, date_acquisition, statut, description)
     VALUES ($1, $2, $3, $4, $5, $6)
     RETURNING *`,
    [
      nom,
      type,
      numero_serie || null,
      date_acquisition || null,
      statut || 'Disponible',
      description || null,
    ]
  );
 
  return result.rows[0];
};
 
// ─── Modifier un équipement ───────────────────────────────────────────────────
const update = async (id, { nom, type, numero_serie, date_acquisition, statut, description }) => {
 
  // Vérifier que l'équipement existe
  await getById(id);
 
  const result = await pool.query(
    `UPDATE equipements
     SET nom             = COALESCE($1, nom),
         type            = COALESCE($2, type),
         numero_serie    = COALESCE($3, numero_serie),
         date_acquisition = COALESCE($4, date_acquisition),
         statut          = COALESCE($5, statut),
         description     = COALESCE($6, description)
     WHERE id_equipement = $7
     RETURNING *`,
    [nom, type, numero_serie, date_acquisition, statut, description, id]
  );
 
  return result.rows[0];
};
 
// ─── Changer uniquement le statut ────────────────────────────────────────────
const updateStatut = async (id, statut) => {
  const statutsValides = [
    'Disponible',
    'En cours d\'utilisation',
    'En maintenance',
    'En panne',
    'Hors service',
  ];
 
  if (!statutsValides.includes(statut)) {
    throw new Error('STATUT_INVALIDE');
  }
 
  // Vérifier que l'équipement existe
  await getById(id);
 
  const result = await pool.query(
    `UPDATE equipements SET statut = $1 WHERE id_equipement = $2 RETURNING *`,
    [statut, id]
  );
 
  return result.rows[0];
};
 
// ─── Supprimer un équipement ──────────────────────────────────────────────────
const remove = async (id) => {
  // Vérifier que l'équipement existe
  await getById(id);
 
  await pool.query(
    'DELETE FROM equipements WHERE id_equipement = $1',
    [id]
  );
};
 
// ─── Statistiques des équipements ─────────────────────────────────────────────
const getStats = async () => {
  const result = await pool.query(`
    SELECT 
      COUNT(*) FILTER (WHERE statut = 'Disponible')              AS disponibles,
      COUNT(*) FILTER (WHERE statut = 'En cours d''utilisation') AS en_utilisation,
      COUNT(*) FILTER (WHERE statut = 'En maintenance')          AS en_maintenance,
      COUNT(*) FILTER (WHERE statut = 'En panne')                AS en_panne,
      COUNT(*) FILTER (WHERE statut = 'Hors service')            AS hors_service,
      COUNT(*)                                                    AS total
    FROM equipements
  `);
 
  return result.rows[0];
};
 
module.exports = { getAll, getById, create, update, updateStatut, remove, getStats };