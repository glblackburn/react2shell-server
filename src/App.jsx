import { useState, useEffect } from 'react';

function App() {
  const [message, setMessage] = useState('');
  const [loading, setLoading] = useState(false);
  const [versionInfo, setVersionInfo] = useState(null);
  const [versionLoading, setVersionLoading] = useState(true);

  // Fetch version information on mount
  useEffect(() => {
    const fetchVersion = async (isRetry = false) => {
      try {
        const response = await fetch('/api/version');
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }
        const data = await response.json();
        setVersionInfo(data);
        setVersionLoading(false);
      } catch (error) {
        console.error('Error fetching version info:', error);
        // Retry once after a short delay in case server is starting up
        if (!isRetry) {
          setTimeout(() => {
            fetchVersion(true);
          }, 1000);
        } else {
          // Retry failed, show error
          setVersionInfo(null);
          setVersionLoading(false);
        }
      }
    };
    fetchVersion();
  }, []);

  const handleClick = async () => {
    setLoading(true);
    setMessage('');
    
    try {
      const response = await fetch('/api/hello');
      const data = await response.json();
      setMessage(data.message);
    } catch (error) {
      setMessage('Error: Could not connect to server');
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="app">
      <div className="container">
        {/* Version Information Display */}
        <div className="version-info">
          <h2 className="version-title">Security Testing Environment</h2>
          {versionLoading ? (
            <div className="version-loading">Loading version information...</div>
          ) : versionInfo ? (
            <div className="version-details">
              <div className="version-item">
                <span className="version-label">Frontend React:</span>
                <span className={`version-value ${versionInfo.vulnerable ? 'vulnerable' : 'fixed'}`}>
                  {versionInfo.react} {versionInfo.vulnerable && '⚠️ VULNERABLE'}
                  {!versionInfo.vulnerable && '✅ FIXED'}
                </span>
              </div>
              <div className="version-item">
                <span className="version-label">React-DOM:</span>
                <span className="version-value">{versionInfo.reactDom}</span>
              </div>
              <div className="version-item">
                <span className="version-label">Backend Node.js:</span>
                <span className="version-value">{versionInfo.node}</span>
              </div>
              <div className="version-status">
                Status: <strong className={versionInfo.vulnerable ? 'status-vulnerable' : 'status-fixed'}>
                  {versionInfo.status}
                </strong>
              </div>
            </div>
          ) : (
            <div className="version-error">Unable to load version information</div>
          )}
        </div>

        <button 
          className="big-red-button" 
          onClick={handleClick}
          disabled={loading}
        >
          {loading ? 'Loading...' : 'press me to say hello'}
        </button>
        
        {message && (
          <div className="message">
            {message}
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
