const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/health', (req, res) => res.status(200).send('ok'));

app.get('/', (req, res) => {
  const env = process.env.APP_ENV || 'unknown';
  const secretSample = process.env.APP_SECRET ? 'present' : 'missing';
  res.send(`Hello from example-saas-app! env=${env}, secret=${secretSample}`);
});

app.listen(port, () => {
  console.log(`Server listening on port ${port}`);
});
