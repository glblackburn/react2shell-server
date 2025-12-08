# React Hello World Server

A React application with a backend server that displays a big red button. When clicked, the button sends a request to the server, which responds with "Hello World!".

## Features

- Big red button UI with smooth animations
- Express.js backend server
- React frontend with version switching capability
- Easy switching between React versions: 19.0, 19.1.0, 19.1.1, and 19.2.0

## React Version Switching

This project supports easy switching between different React versions using a Makefile.

### Available React Versions

- React 19.0
- React 19.1.0
- React 19.1.1
- React 19.2.0

### Makefile Commands

```bash
# Switch to a specific React version
make react-19.0      # Switch to React 19.0
make react-19.1.0    # Switch to React 19.1.0
make react-19.1.1    # Switch to React 19.1.1
make react-19.2.0    # Switch to React 19.2.0

# Check current React version
make current-version

# Install dependencies for current version
make install

# Clean node_modules and package-lock.json
make clean

# Show help
make help
```

## Setup

1. **Clone the repository** (if applicable) or navigate to the project directory

2. **Switch to your desired React version** (defaults to 19.0):
   ```bash
   make react-19.0
   ```
   Or choose any other version:
   ```bash
   make react-19.1.0
   make react-19.1.1
   make react-19.2.0
   ```

3. **Verify the React version**:
   ```bash
   make current-version
   ```

## Development

### Development Mode (with hot reload)

1. **Start the Vite dev server** (runs on port 5173):
   ```bash
   npm run dev
   ```

2. **In a separate terminal, start the Express server** (runs on port 3000):
   ```bash
   npm run server
   ```

3. **Open your browser** to `http://localhost:5173`

The Vite dev server is configured to proxy API requests to the Express server.

### Production Mode

1. **Build the React app**:
   ```bash
   npm run build
   ```

2. **Start the server**:
   ```bash
   npm run server
   ```

   Or use the combined command:
   ```bash
   npm start
   ```

3. **Open your browser** to `http://localhost:3000`

## Project Structure

```
react2shell-server/
├── Makefile                  # React version switching commands
├── package.json              # Dependencies (React version updated by Makefile)
├── vite.config.js            # Vite build configuration
├── server.js                 # Express server
├── index.html                # HTML entry point
├── src/
│   ├── App.jsx               # Main React component
│   ├── index.js              # React entry point
│   └── App.css               # Styles
└── dist/                     # Build output (generated)
```

## API Endpoint

- **GET /api/hello**
  - Returns: `{ "message": "Hello World!" }`

## Switching React Versions

To switch React versions during development:

1. **Stop any running servers**

2. **Switch to the desired version**:
   ```bash
   make react-19.2.0
   ```

3. **Verify the switch**:
   ```bash
   make current-version
   ```

4. **Restart your development servers**

## Requirements

- Node.js (v18 or higher recommended)
- npm
- make (usually pre-installed on macOS/Linux)

## Troubleshooting

### If `make` command is not found

On Windows, you may need to use WSL or install make. Alternatively, you can manually update `package.json` and run `npm install`.

### If dependencies fail to install

Try cleaning and reinstalling:
```bash
make clean
make install
```

### Port already in use

If port 3000 or 5173 is already in use, you can:
- Change the port in `server.js` (PORT environment variable)
- Change the port in `vite.config.js` (server.port)

## License

ISC
