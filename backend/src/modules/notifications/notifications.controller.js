const notificationsService = require('./notifications.service');
 
// ─── Envoyer une notification générale à tous (admin seulement) ───────────────
const sendToAll = async (req, res) => {
  try {
    const { title, body, data } = req.body;
 
    if (!title || !body) {
      return res.status(400).json({
        success: false,
        message: 'Les champs title et body sont obligatoires',
      });
    }
 
    const result = await notificationsService.sendToAll({ title, body, data });
 
    return res.status(200).json({
      success: true,
      message: 'Notification générale envoyée',
      data: result,
    });
 
  } catch (error) {
    console.error('Erreur sendToAll notification :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
// ─── Envoyer une notification à un utilisateur (admin seulement) ──────────────
const sendToUser = async (req, res) => {
  try {
    const { id_utilisateur, title, body, data } = req.body;
 
    if (!id_utilisateur || !title || !body) {
      return res.status(400).json({
        success: false,
        message: 'Les champs id_utilisateur, title et body sont obligatoires',
      });
    }
 
    const result = await notificationsService.sendToUser(id_utilisateur, { title, body, data });
 
    return res.status(200).json({
      success: true,
      message: 'Notification envoyée',
      data: result,
    });
 
  } catch (error) {
    if (error.message === 'UTILISATEUR_NOT_FOUND') {
      return res.status(404).json({ success: false, message: 'Utilisateur non trouvé' });
    }
    console.error('Erreur sendToUser notification :', error.message);
    return res.status(500).json({ success: false, message: 'Erreur serveur' });
  }
};
 
module.exports = { sendToAll, sendToUser };