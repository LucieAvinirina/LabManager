
const reservationsService = require('./reservations.service');
 
// ─── Lister les réservations ──────────────────────────────────────────────────
const getAll = async (req, res) => {
  try {
    const { statut, date } = req.query;
    const reservations = await reservationsService.getAll({ statut, date }, req.user);
 
    return res.status(200).json({
      success: true,
      count: reservations.length,
      data: reservations,
    });
  } catch (error) {
    console.error('Erreur getAll reservations :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Détail d'une réservation ─────────────────────────────────────────────────
const getById = async (req, res) => {
  try {
    const reservation = await reservationsService.getById(req.params.id, req.user);
    return res.status(200).json({ success: true, data: reservation });
  } catch (error) {
    if (error.message === 'RESERVATION_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Réservation non trouvée' });
    }
    if (error.message === 'ACCES_REFUSE') {
      return res.status(403).json({ success: false, message: 'Accès refusé' });
    }
    console.error('Erreur getById reservation :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Créer une réservation ────────────────────────────────────────────────────
const create = async (req, res) => {
  try {
    const {
      ids_equipements,
      date_heure_debut,
      date_heure_fin,
      type_reservation,
      est_recurrente,
      frequence,
      motif,
    } = req.body;
 
    // Validation des champs obligatoires
    if (!date_heure_debut || !date_heure_fin) {
      return res.status(400).json({
        success: false,
        message: 'Les champs date_heure_debut et date_heure_fin sont obligatoires',
      });
    }
 
    // Vérifier que la date de fin est après la date de début
    if (new Date(date_heure_fin) <= new Date(date_heure_debut)) {
      return res.status(400).json({
        success: false,
        message: 'La date de fin doit être après la date de début',
      });
    }
 
    // Vérifier que la réservation est dans le futur
    if (new Date(date_heure_debut) < new Date()) {
      return res.status(400).json({
        success: false,
        message: 'Impossible de réserver dans le passé',
      });
    }
 
    if (type_reservation !== 'salle_entiere' && (!ids_equipements || ids_equipements.length === 0)) {
      return res.status(400).json({
        success: false,
        message: 'Veuillez sélectionner au moins un équipement',
      });
    }
 
    const reservation = await reservationsService.create({
      id_utilisateur: req.user.id,
      ids_equipements,
      date_heure_debut,
      date_heure_fin,
      type_reservation,
      est_recurrente,
      frequence,
      motif,
      role: req.user.role,
    });
 
    return res.status(201).json({
      success: true,
      message: 'Réservation créée avec succès. En attente de validation',
      data: reservation,
    });
 
  } catch (error) {
    if (error.message === 'PERMISSION_DENIED_SALLE') {
      return res.status(403).json({
        success: false,
        message: 'Seuls les enseignants peuvent réserver la salle entière',
      });
    }
    if (error.message === 'AUCUN_EQUIPEMENT') {
      return res.status(400).json({
        success: false,
        message: 'Aucun équipement disponible trouvé',
      });
    }
    if (error.message.startsWith('EQUIPEMENT_INDISPONIBLE')) {
      const id = error.message.split(':')[1];
      return res.status(409).json({
        success: false,
        message: `L'équipement ${id} est en panne ou en maintenance`,
      });
    }
    if (error.message.startsWith('CONFLIT_RESERVATION')) {
      const conflits = JSON.parse(error.message.split('CONFLIT_RESERVATION:')[1]);
      return res.status(409).json({
        success: false,
        message: 'Conflit de réservation détecté',
        conflits,
      });
    }
    console.error('Erreur create reservation :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Valider ou refuser (admin seulement) ────────────────────────────────────
const valider = async (req, res) => {
  try {
    const { statut } = req.body;
 
    if (!statut) {
      return res.status(400).json({
        success: false,
        message: 'Le champ statut est obligatoire (Confirmée ou Annulée)',
      });
    }
 
    const reservation = await reservationsService.valider(
      req.params.id,
      statut,
      req.user.id
    );
 
    return res.status(200).json({
      success: true,
      message: `Réservation ${statut.toLowerCase()} avec succès`,
      data: reservation,
    });
 
  } catch (error) {
    if (error.message === 'RESERVATION_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Réservation non trouvée' });
    }
    if (error.message === 'RESERVATION_DEJA_TRAITEE') {
      return res.status(409).json({
        success: false,
        message: 'Cette réservation a déjà été traitée',
      });
    }
    if (error.message === 'STATUT_INVALIDE') {
      return res.status(400).json({
        success: false,
        message: 'Statut invalide. Valeurs acceptées : Confirmée, Annulée',
      });
    }
    console.error('Erreur valider reservation :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Annuler une réservation ──────────────────────────────────────────────────
const annuler = async (req, res) => {
  try {
    const result = await reservationsService.annuler(req.params.id, req.user);
    return res.status(200).json({ success: true, message: result.message });
  } catch (error) {
    if (error.message === 'RESERVATION_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Réservation non trouvée' });
    }
    if (error.message === 'ACCES_REFUSE') {
      return res.status(403).json({ success: false, message: 'Accès refusé' });
    }
    if (error.message === 'RESERVATION_DEJA_TRAITEE') {
      return res.status(409).json({
        success: false,
        message: 'Cette réservation est déjà annulée ou terminée',
      });
    }
    console.error('Erreur annuler reservation :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Historique personnel ─────────────────────────────────────────────────────
const getHistorique = async (req, res) => {
  try {
    const historique = await reservationsService.getHistorique(req.user.id);
    return res.status(200).json({ success: true, count: historique.length, data: historique });
  } catch (error) {
    console.error('Erreur getHistorique :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
module.exports = { getAll, getById, create, valider, annuler, getHistorique };