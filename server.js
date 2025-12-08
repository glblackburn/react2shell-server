import express from 'express';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readFileSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for development
app.use((req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  if (req.method === 'OPTIONS') {
    res.sendStatus(200);
  } else {
    next();
  }
});

// Parse JSON bodies
app.use(express.json());

// Read package.json for version info
const packageJson = JSON.parse(readFileSync(join(__dirname, 'package.json'), 'utf-8'));

// Import version constants
import { isVulnerableVersion, getVersionStatus } from './config/versions.js';

// Version info endpoint
app.get('/api/version', (req, res) => {
  try {
    const reactVersion = packageJson.dependencies.react || 'unknown';
    const reactDomVersion = packageJson.dependencies['react-dom'] || 'unknown';
    const nodeVersion = process.version;

    // Determine if vulnerable using shared constants
    const isVulnerable = isVulnerableVersion(reactVersion);
    const status = getVersionStatus(reactVersion);

    res.json({
      react: reactVersion,
      reactDom: reactDomVersion,
      node: nodeVersion,
      vulnerable: isVulnerable,
      status: status
    });
  } catch (error) {
    console.error('Error in /api/version:', error);
    res.status(500).json({ error: 'Failed to get version information' });
  }
});

// API endpoint
app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello World!' });
});

// Serve static files from dist directory (Vite build output)
app.use(express.static(join(__dirname, 'dist')));

// Serve index.html for all routes (SPA routing)
app.get('*', (req, res) => {
  try {
    const htmlPath = join(__dirname, 'dist', 'index.html');
    const html = readFileSync(htmlPath, 'utf-8');
    res.send(html);
  } catch (error) {
    res.status(500).send('Please run "npm run build" first');
  }
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`API endpoint: http://localhost:${PORT}/api/hello`);
  console.log(`Version endpoint: http://localhost:${PORT}/api/version`);
});
