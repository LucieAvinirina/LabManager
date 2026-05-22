
const pool = require('../../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
 
// ─── Inscription ──────────────────────────────────────────────────────────────
const register = async ({ nom, prenom, email, mot_de_passe, role }) => {
 
  // 1. Vérifier si l'email existe déjà
  const existingUser = await pool.query(
    'SELECT id_utilisateur FROM utilisateurs WHERE email = $1',
    [email]
  );
  if (existingUser.rows.length > 0) {
    throw new Error('EMAIL_ALREADY_EXISTS');
  }
 
  // 2. Vérifier que le rôle est valide
  const rolesAutorises = ['etudiant', 'enseignant', 'admin'];
  if (role && !rolesAutorises.includes(role)) {
    throw new Error('ROLE_INVALIDE');
  }
 
  // 3. Hacher le mot de passe
  const saltRounds = 10;
  const mot_de_passe_hash = await bcrypt.hash(mot_de_passe, saltRounds);
 
  // 4. Insérer l'utilisateur en base
  const result = await pool.query(
    `INSERT INTO utilisateurs (nom, prenom, email, mot_de_passe_hash, role)
     VALUES ($1, $2, $3, $4, $5)
     RETURNING id_utilisateur, nom, prenom, email, role, date_creation`,
    [nom, prenom, email, mot_de_passe_hash, role || 'etudiant']
  );
 
  return result.rows[0];
};
 
// ─── Connexion ────────────────────────────────────────────────────────────────
const login = async ({ email, mot_de_passe }) => {
 
  // 1. Chercher l'utilisateur par email
  const result = await pool.query(
    `SELECT id_utilisateur, nom, prenom, email, mot_de_passe_hash, role, est_actif
     FROM utilisateurs WHERE email = $1`,
    [email]
  );
 
  if (result.rows.length === 0) {
    throw new Error('IDENTIFIANTS_INVALIDES');
  }
 
  const user = result.rows[0];
 
  // 2. Vérifier si le compte est actif
  if (!user.est_actif) {
    throw new Error('COMPTE_DESACTIVE');
  }
 
  // 3. Vérifier le mot de passe
  const motDePasseValide = await bcrypt.compare(mot_de_passe, user.mot_de_passe_hash);
  if (!motDePasseValide) {
    throw new Error('IDENTIFIANTS_INVALIDES');
  }
 
  // 4. Générer le token JWT
  const token = jwt.sign(
    {
      id:    user.id_utilisateur,
      email: user.email,
      role:  user.role,
    },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN }
  );
 
  // 5. Retourner le token et les infos utilisateur (sans le hash)
  return {
    token,
    user: {
      id:     user.id_utilisateur,
      nom:    user.nom,
      prenom: user.prenom,
      email:  user.email,
      role:   user.role,
    },
  };
};
 
// ─── Mise à jour du FCM token (notifications push) ───────────────────────────
const updateFcmToken = async (id_utilisateur, fcm_token) => {
  await pool.query(
    'UPDATE utilisateurs SET fcm_token = $1 WHERE id_utilisateur = $2',
    [fcm_token, id_utilisateur]
  );
};
 
module.exports = { register, login, updateFcmToken };