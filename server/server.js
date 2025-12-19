import express from 'express';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import { readFileSync, existsSync } from 'fs';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const app = express();
const PORT = process.env.PORT || 3000;

// Check framework mode and if dist directory exists
const frameworkModeFile = join(__dirname, '..', '.framework-mode');
let isViteMode = true; // Default to Vite
if (existsSync(frameworkModeFile)) {
  try {
    const mode = readFileSync(frameworkModeFile, 'utf-8').trim();
    isViteMode = mode !== 'nextjs';
  } catch (error) {
    // Default to Vite if can't read file
  }
}

const distExists = existsSync(join(__dirname, '..', 'dist'));

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

// Import version constants
import { isVulnerableVersion, getVersionStatus } from './config/versions.js';

// Helper function to get package.json path based on framework mode
function getPackageJsonPath() {
  if (isViteMode) {
    // Vite mode: read from frameworks/vite-react/package.json
    return join(__dirname, '..', 'frameworks', 'vite-react', 'package.json');
  } else {
    // Next.js mode: read from frameworks/nextjs/package.json
    return join(__dirname, '..', 'frameworks', 'nextjs', 'package.json');
  }
}

// Version info endpoint
app.get('/api/version', (req, res) => {
  try {
    // Read package.json from the correct framework directory
    const packageJsonPath = getPackageJsonPath();
    let packageJson;
    
    if (existsSync(packageJsonPath)) {
      packageJson = JSON.parse(readFileSync(packageJsonPath, 'utf-8'));
    } else {
      // Framework package.json should always exist - this is an error condition
      throw new Error(`Framework package.json not found at ${packageJsonPath}`);
    }
    
    const reactVersion = packageJson.dependencies?.react || 'unknown';
    const reactDomVersion = packageJson.dependencies?.['react-dom'] || 'unknown';
    const nodeVersion = process.version;
    
    // For Next.js, also include Next.js version
    let response = {
      react: reactVersion,
      reactDom: reactDomVersion,
      node: nodeVersion,
    };
    
    if (!isViteMode) {
      response.nextjs = packageJson.dependencies?.next || 'unknown';
    }

    // Determine if vulnerable using shared constants
    const isVulnerable = isVulnerableVersion(reactVersion);
    const status = getVersionStatus(reactVersion);
    
    response.vulnerable = isVulnerable;
    response.status = status;

    res.json(response);
  } catch (error) {
    console.error('Error in /api/version:', error);
    res.status(500).json({ error: 'Failed to get version information' });
  }
});

// API endpoint
app.get('/api/hello', (req, res) => {
  res.json({ message: 'Hello World!' });
});

// Only serve static files if dist directory exists (production build)
// In Vite dev mode, Vite dev server handles frontend on port 5173
if (distExists) {
  // Serve static files from dist directory (Vite build output)
  app.use(express.static(join(__dirname, '..', 'dist')));

  // Serve index.html for all routes (SPA routing)
  app.get('*', (req, res) => {
    try {
      const htmlPath = join(__dirname, '..', 'dist', 'index.html');
      const html = readFileSync(htmlPath, 'utf-8');
      res.send(html);
    } catch (error) {
      res.status(500).send('Please run "npm run build" first');
    }
  });
} else if (isViteMode) {
  // In Vite dev mode, only serve API endpoints
  // Frontend is served by Vite dev server on port 5173
  app.get('/', (req, res) => {
    res.status(200).json({
      message: 'Express API server running',
      note: 'Frontend is served by Vite dev server on http://localhost:5173',
      endpoints: {
        hello: '/api/hello',
        version: '/api/version'
      }
    });
  });
} else {
  // Next.js mode - this server shouldn't be running, but if it is, just serve API
  app.get('/', (req, res) => {
    res.status(200).json({
      message: 'Express API server running',
      note: 'Next.js handles frontend and API routes on port 3000',
      endpoints: {
        hello: '/api/hello',
        version: '/api/version'
      }
    });
  });
}

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`API endpoint: http://localhost:${PORT}/api/hello`);
  console.log(`Version endpoint: http://localhost:${PORT}/api/version`);
});
