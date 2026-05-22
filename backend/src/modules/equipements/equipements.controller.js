
const equipementsService = require('./equipements.service');
 
// ─── Lister tous les équipements ─────────────────────────────────────────────
const getAll = async (req, res) => {
  try {
    const { type, statut } = req.query;
    const equipements = await equipementsService.getAll({ type, statut });
 
    return res.status(200).json({
      success: true,
      count: equipements.length,
      data: equipements,
    });
  } catch (error) {
    console.error('Erreur getAll equipements :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Obtenir un équipement par ID ─────────────────────────────────────────────
const getById = async (req, res) => {
  try {
    const equipement = await equipementsService.getById(req.params.id);
 
    return res.status(200).json({
      success: true,
      data: equipement,
    });
  } catch (error) {
    if (error.message === 'EQUIPEMENT_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Équipement non trouvé' });
    }
    console.error('Erreur getById equipement :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Créer un équipement (admin seulement) ───────────────────────────────────
const create = async (req, res) => {
  try {
    const { nom, type, numero_serie, date_acquisition, statut, description } = req.body;
 
    // Validation champs obligatoires
    if (!nom || !type) {
      return res.status(400).json({
        success: false,
        message: 'Les champs nom et type sont obligatoires',
      });
    }
 
    const equipement = await equipementsService.create({
      nom, type, numero_serie, date_acquisition, statut, description,
    });
 
    return res.status(201).json({
      success: true,
      message: 'Équipement créé avec succès',
      data: equipement,
    });
  } catch (error) {
    if (error.message === 'NUMERO_SERIE_EXISTS') {
      return res.status(409).json({
        success: false,
        message: 'Ce numéro de série existe déjà',
      });
    }
    console.error('Erreur create equipement :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Modifier un équipement (admin seulement) ────────────────────────────────
const update = async (req, res) => {
  try {
    const equipement = await equipementsService.update(req.params.id, req.body);
 
    return res.status(200).json({
      success: true,
      message: 'Équipement modifié avec succès',
      data: equipement,
    });
  } catch (error) {
    if (error.message === 'EQUIPEMENT_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Équipement non trouvé' });
    }
    console.error('Erreur update equipement :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Changer le statut (admin seulement) ─────────────────────────────────────
const updateStatut = async (req, res) => {
  try {
    const { statut } = req.body;
 
    if (!statut) {
      return res.status(400).json({
        success: false,
        message: 'Le champ statut est obligatoire',
      });
    }
 
    const equipement = await equipementsService.updateStatut(req.params.id, statut);
 
    return res.status(200).json({
      success: true,
      message: `Statut mis à jour : ${statut}`,
      data: equipement,
    });
  } catch (error) {
    if (error.message === 'EQUIPEMENT_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Équipement non trouvé' });
    }
    if (error.message === 'STATUT_INVALIDE') {
      return res.status(400).json({
        success: false,
        message: 'Statut invalide. Valeurs acceptées : Disponible, En cours d\'utilisation, En maintenance, En panne, Hors service',
      });
    }
    console.error('Erreur updateStatut :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Supprimer un équipement (admin seulement) ───────────────────────────────
const remove = async (req, res) => {
  try {
    await equipementsService.remove(req.params.id);
 
    return res.status(200).json({
      success: true,
      message: 'Équipement supprimé avec succès',
    });
  } catch (error) {
    if (error.message === 'EQUIPEMENT_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Équipement non trouvé' });
    }
    console.error('Erreur remove equipement :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Statistiques (admin + enseignant) ───────────────────────────────────────
const getStats = async (req, res) => {
  try {
    const stats = await equipementsService.getStats();
 
    return res.status(200).json({
      success: true,
      data: stats,
    });
  } catch (error) {
    console.error('Erreur getStats equipements :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
module.exports = { getAll, getById, create, update, updateStatut, remove, getStats };