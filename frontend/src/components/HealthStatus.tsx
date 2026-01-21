export interface HealthStatusProps {
  status: 'healthy' | 'unhealthy' | 'loading'
  message?: string
}

export function HealthStatus({ status, message }: HealthStatusProps) {
  const statusColors = {
    healthy: '#22c55e',
    unhealthy: '#ef4444',
    loading: '#f59e0b',
  }

  const statusLabels = {
    healthy: 'Healthy',
    unhealthy: 'Unhealthy',
    loading: 'Loading...',
  }

  return (
    <div
      data-testid="health-status"
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: '8px',
        padding: '12px 16px',
        borderRadius: '8px',
        backgroundColor: '#f8fafc',
        border: '1px solid #e2e8f0',
      }}
    >
      <span
        data-testid="health-indicator"
        style={{
          width: '12px',
          height: '12px',
          borderRadius: '50%',
          backgroundColor: statusColors[status],
        }}
      />
      <span data-testid="health-label" style={{ fontWeight: 500 }}>
        {statusLabels[status]}
      </span>
      {message && (
        <span data-testid="health-message" style={{ color: '#64748b' }}>
          - {message}
        </span>
      )}
    </div>
  )
}
