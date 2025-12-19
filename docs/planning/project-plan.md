# React Server Project Plan

## Overview
Create a React application with a backend server that displays a big red button. When clicked, the button sends a request to the server, which responds with "Hello World!".

## Project Structure

```
react2shell-server/
├── Makefile                  # React version switching commands
├── package.json              # Project dependencies and scripts (React version updated by Makefile)
├── vite.config.js            # Vite build configuration
├── server.js                 # Express server (serves React app + API endpoint)
├── index.html                # HTML entry point for Vite
├── src/                      # React source code
│   ├── App.jsx               # Main React component with button
│   ├── index.js              # React entry point
│   └── App.css               # Styles for the button
├── dist/                     # Build output (generated)
├── .gitignore                # Git ignore rules
└── README.md                 # Setup and run instructions
```

## Components to Create

### 1. Backend Server (`server.js`)
- Express.js server
- Serve static files from `public/` directory
- API endpoint: `GET /api/hello` that returns `{ message: "Hello World!" }`
- Handle React routing (serve index.html for all routes)

### 2. React Frontend
- **`src/index.js`**: React entry point that renders the App component
- **`src/App.jsx`**: Main component containing:
  - Big red button with text "press me to say hello"
  - State to store the server response
  - Click handler that fetches from `/api/hello`
  - Display area for the "Hello World!" response
- **`src/App.css`**: Styles for the big red button

### 3. HTML Entry Point (`public/index.html`)
- Basic HTML structure
- Root div for React to mount
- Script tags for React app

### 4. Configuration Files
- **`package.json`**: 
  - Dependencies: `express`, `react`, `react-dom` (versions switchable via Makefile)
  - Dev dependencies: `@vitejs/plugin-react`, `vite`
  - Scripts: `start` (builds and runs server), `dev` (development mode), `server` (runs server only)
- **`Makefile`**: 
  - Targets for switching React versions: `react-19.0`, `react-19.1.0`, `react-19.1.1`, `react-19.2.0`
  - Helper targets: `current-version`, `install`, `clean`
- **`vite.config.js`**: Vite configuration with proxy for API calls

## Technology Stack

- **Backend**: Node.js + Express.js
- **Frontend**: React (with JSX)
- **Build Tool**: Vite (recommended) or Create React App
- **Styling**: CSS (or could use CSS modules/styled-components)

## React Version Switching

The project supports easy switching between React versions using a Makefile:
- `make react-19.0` - Switch to React 19.0
- `make react-19.1.0` - Switch to React 19.1.0
- `make react-19.1.1` - Switch to React 19.1.1
- `make react-19.2.0` - Switch to React 19.2.0
- `make current-version` - Show currently installed React version
- `make install` - Install dependencies for current version
- `make clean` - Remove node_modules and package-lock.json

Each version switch target:
1. Updates `package.json` with the specified React and React-DOM version
2. Runs `npm install` to install the new version
3. Confirms the switch was successful

## Implementation Steps

1. ✅ Create Makefile with React version switching targets
2. ✅ Create base package.json with placeholder React version
3. ✅ Create server.js with Express setup
4. ✅ Create React components (App.jsx, index.js)
5. ✅ Create HTML entry point and CSS
6. ✅ Set up Vite build configuration
7. ✅ Create .gitignore
8. ✅ Update PLAN.md with version switching details
9. Create README with setup instructions

## API Endpoint Specification

- **Route**: `GET /api/hello`
- **Response**: 
  ```json
  {
    "message": "Hello World!"
  }
  ```

## User Flow

1. User visits the application
2. Sees a big red button with text "press me to say hello"
3. User clicks the button
4. Frontend sends GET request to `/api/hello`
5. Server responds with "Hello World!"
6. Frontend displays the message on the page

## Alternative Approach (Simpler)

If you prefer a simpler setup without a separate build step:
- Use Express to serve a single HTML file with inline React (via CDN)
- This eliminates the need for Vite/build tools but is less scalable

## Next Steps

After this plan is approved, I'll implement:
1. All configuration files
2. Backend server with API endpoint
3. React frontend with button component
4. Styling for the big red button
5. README with setup instructions
