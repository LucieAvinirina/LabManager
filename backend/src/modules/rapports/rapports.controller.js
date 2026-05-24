const rapportsService = require('./rapports.service');
 
// ─── Tableau de bord global (admin) ──────────────────────────────────────────
const getDashboard = async (req, res) => {
  try {
    const dashboard = await rapportsService.getDashboard();
    return res.status(200).json({ success: true, data: dashboard });
  } catch (error) {
    console.error('Erreur getDashboard :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Taux d'occupation par période ───────────────────────────────────────────
const getTauxOccupation = async (req, res) => {
  try {
    const { date_debut, date_fin } = req.query;
 
    if (!date_debut || !date_fin) {
      return res.status(400).json({
        success: false,
        message: 'Les paramètres date_debut et date_fin sont obligatoires',
      });
    }
 
    const data = await rapportsService.getTauxOccupation(date_debut, date_fin);
    return res.status(200).json({ success: true, count: data.length, data });
 
  } catch (error) {
    console.error('Erreur getTauxOccupation :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Équipements les plus utilisés ───────────────────────────────────────────
const getEquipementsLesPlusUtilises = async (req, res) => {
  try {
    const limite = parseInt(req.query.limite) || 10;
    const data = await rapportsService.getEquipementsLesPlusUtilises(limite);
    return res.status(200).json({ success: true, data });
  } catch (error) {
    console.error('Erreur getEquipementsLesPlusUtilises :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Équipements les plus défaillants ────────────────────────────────────────
const getEquipementsLesPlusDefaillants = async (req, res) => {
  try {
    const limite = parseInt(req.query.limite) || 10;
    const data = await rapportsService.getEquipementsLesPlusDefaillants(limite);
    return res.status(200).json({ success: true, data });
  } catch (error) {
    console.error('Erreur getEquipementsLesPlusDefaillants :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Réservations par utilisateur ────────────────────────────────────────────
const getReservationsParUtilisateur = async (req, res) => {
  try {
    const data = await rapportsService.getReservationsParUtilisateur();
    return res.status(200).json({ success: true, data });
  } catch (error) {
    console.error('Erreur getReservationsParUtilisateur :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Statistiques personnelles ────────────────────────────────────────────────
const getStatsPersonnelles = async (req, res) => {
  try {
    const data = await rapportsService.getStatsPersonnelles(req.user.id);
    return res.status(200).json({ success: true, data });
  } catch (error) {
    console.error('Erreur getStatsPersonnelles :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Export CSV ───────────────────────────────────────────────────────────────
const exportCSV = async (req, res) => {
  try {
    const { date_debut, date_fin } = req.query;
 
    if (!date_debut || !date_fin) {
      return res.status(400).json({
        success: false,
        message: 'Les paramètres date_debut et date_fin sont obligatoires',
      });
    }
 
    const data = await rapportsService.getReservationsCSV(date_debut, date_fin);
 
    // Construire le contenu CSV
    const headers = [
      'ID', 'Utilisateur', 'Rôle', 'Début', 'Fin',
      'Type', 'Statut', 'Motif', 'Date création'
    ].join(',');
 
    const rows = data.map(r => [
      r.id_reservation,
      `"${r.utilisateur}"`,
      r.role,
      r.date_heure_debut,
      r.date_heure_fin,
      r.type_reservation,
      r.statut,
      `"${r.motif || ''}"`,
      r.date_creation,
    ].join(','));
 
    const csv = [headers, ...rows].join('\n');
 
    // Envoyer comme fichier téléchargeable
    res.setHeader('Content-Type', 'text/csv; charset=utf-8');
    res.setHeader('Content-Disposition',
      `attachment; filename="reservations_${date_debut}_${date_fin}.csv"`
    );
 
    return res.status(200).send('\uFEFF' + csv); // BOM pour Excel
 
  } catch (error) {
    console.error('Erreur exportCSV :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
module.exports = {
  getDashboard,
  getTauxOccupation,
  getEquipementsLesPlusUtilises,
  getEquipementsLesPlusDefaillants,
  getReservationsParUtilisateur,
  getStatsPersonnelles,
  exportCSV,
};