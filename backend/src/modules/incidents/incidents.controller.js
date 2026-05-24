
const incidentsService = require('./incidents.service');
 
// ─── Lister tous les incidents ────────────────────────────────────────────────
const getAll = async (req, res) => {
  try {
    const { statut, id_equipement } = req.query;
    const incidents = await incidentsService.getAll({ statut, id_equipement }, req.user);
 
    return res.status(200).json({
      success: true,
      count: incidents.length,
      data: incidents,
    });
  } catch (error) {
    console.error('Erreur getAll incidents :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Détail d'un incident ─────────────────────────────────────────────────────
const getById = async (req, res) => {
  try {
    const incident = await incidentsService.getById(req.params.id, req.user);
    return res.status(200).json({ success: true, data: incident });
  } catch (error) {
    if (error.message === 'INCIDENT_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Incident non trouvé' });
    }
    if (error.message === 'ACCES_REFUSE') {
      return res.status(403).json({ success: false, message: 'Accès refusé' });
    }
    console.error('Erreur getById incident :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Signaler un incident ─────────────────────────────────────────────────────
const create = async (req, res) => {
  try {
    const { id_equipement, description, photo_url } = req.body;
 
    // Validation des champs obligatoires
    if (!id_equipement || !description) {
      return res.status(400).json({
        success: false,
        message: 'Les champs id_equipement et description sont obligatoires',
      });
    }
 
    if (description.trim().length < 10) {
      return res.status(400).json({
        success: false,
        message: 'La description doit contenir au moins 10 caractères',
      });
    }
 
    const incident = await incidentsService.create({
      id_equipement,
      id_utilisateur: req.user.id,
      description,
      photo_url,
    });
 
    return res.status(201).json({
      success: true,
      message: 'Incident signalé avec succès. L\'équipement est passé en statut "En panne"',
      data: incident,
    });
 
  } catch (error) {
    if (error.message === 'EQUIPEMENT_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Équipement non trouvé' });
    }
    if (error.message === 'EQUIPEMENT_HORS_SERVICE') {
      return res.status(409).json({
        success: false,
        message: 'Cet équipement est définitivement hors service',
      });
    }
    console.error('Erreur create incident :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Mettre à jour le statut (admin seulement) ───────────────────────────────
const updateStatut = async (req, res) => {
  try {
    const { statut } = req.body;
 
    if (!statut) {
      return res.status(400).json({
        success: false,
        message: 'Le champ statut est obligatoire',
      });
    }
 
    const incident = await incidentsService.updateStatut(
      req.params.id,
      statut,
      req.user.id
    );
 
    return res.status(200).json({
      success: true,
      message: `Incident mis à jour : ${statut}`,
      data: incident,
    });
 
  } catch (error) {
    if (error.message === 'INCIDENT_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Incident non trouvé' });
    }
    if (error.message === 'STATUT_INVALIDE') {
      return res.status(400).json({
        success: false,
        message: 'Statut invalide. Valeurs : Nouveau, En cours de traitement, Résolu, Clôturé',
      });
    }
    console.error('Erreur updateStatut incident :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Statistiques des incidents ───────────────────────────────────────────────
const getStats = async (req, res) => {
  try {
    const stats = await incidentsService.getStats();
    return res.status(200).json({ success: true, data: stats });
  } catch (error) {
    console.error('Erreur getStats incidents :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Incidents par équipement ─────────────────────────────────────────────────
const getByEquipement = async (req, res) => {
  try {
    const incidents = await incidentsService.getByEquipement(req.params.id_equipement);
    return res.status(200).json({
      success: true,
      count: incidents.length,
      data: incidents,
    });
  } catch (error) {
    console.error('Erreur getByEquipement :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
module.exports = { getAll, getById, create, updateStatut, getStats, getByEquipement };