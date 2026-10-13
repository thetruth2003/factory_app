const fs = require('node:fs');
const path = require('node:path');

module.exports = function firebaseProject() {
  let project = process.env.FIREBASE_PROJECT_ID;
  const config = path.resolve(__dirname, '../.firebaserc');
  if (!project && fs.existsSync(config)) {
    project = JSON.parse(fs.readFileSync(config, 'utf8')).projects?.default;
  }
  if (!project || !/^[a-z][a-z0-9-]{4,28}[a-z0-9]$/.test(project)) {
    throw new Error('Set FIREBASE_PROJECT_ID or configure .firebaserc before running this tool.');
  }
  return project;
};
