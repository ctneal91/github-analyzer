import { useState, useEffect } from 'react'
import { HealthStatus } from './components/HealthStatus'
import './App.css'

type HealthStatusType = 'healthy' | 'unhealthy' | 'loading'

function App() {
  const [status, setStatus] = useState<HealthStatusType>('loading')

  // Check health on mount
  useEffect(() => {
    const timeoutId = setTimeout(() => {
      setStatus('healthy')
    }, 1000)
    return () => clearTimeout(timeoutId)
  }, [])

  const checkHealth = () => {
    setStatus('loading')
    // Simulate API call
    setTimeout(() => {
      setStatus('healthy')
    }, 1000)
  }

  return (
    <div className="app">
      <header>
        <h1>GitHub Event Analyzer</h1>
        <p>Dashboard for monitoring GitHub push events</p>
      </header>

      <main>
        <section className="health-section">
          <h2>System Health</h2>
          <HealthStatus status={status} message="API connection status" />
          <button onClick={checkHealth} style={{ marginTop: '16px' }}>
            Check Health
          </button>
        </section>
      </main>
    </div>
  )
}

export default App
