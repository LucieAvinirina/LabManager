const express = require('express');
const router = express.Router();

router.get('/', (req, res) => {
  res.json({ message: 'Module Auth opérationnel' });
});

module.exports = router;