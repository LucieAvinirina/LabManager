const app = require('./src/app');
require('dotenv').config();
 
const PORT = process.env.PORT || 3000;
 
app.listen(PORT, () => {
  console.log(` Serveur LabManager démarré sur le port ${PORT}`);
  console.log(` Mode : ${process.env.NODE_ENV}`);
  console.log(` URL : http://localhost:${PORT}`);
});
 