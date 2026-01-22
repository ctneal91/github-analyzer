export interface HealthStatusProps {
  status: "healthy" | "unhealthy" | "loading";
  message?: string;
}

const STATUS_COLORS = {
  healthy: "#22c55e",
  unhealthy: "#ef4444",
  loading: "#f59e0b",
} as const;

const STATUS_LABELS = {
  healthy: "Healthy",
  unhealthy: "Unhealthy",
  loading: "Loading...",
} as const;

export function HealthStatus({ status, message }: HealthStatusProps) {
  return (
    <div
      data-testid="health-status"
      style={{
        display: "flex",
        alignItems: "center",
        gap: "8px",
        padding: "12px 16px",
        borderRadius: "8px",
        backgroundColor: "#f8fafc",
        border: "1px solid #e2e8f0",
      }}
    >
      <StatusIndicator color={STATUS_COLORS[status]} />
      <StatusLabel label={STATUS_LABELS[status]} />
      {message && <StatusMessage message={message} />}
    </div>
  );
}

interface StatusIndicatorProps {
  color: string;
}

function StatusIndicator({ color }: StatusIndicatorProps) {
  return (
    <span
      data-testid="health-indicator"
      style={{
        width: "12px",
        height: "12px",
        borderRadius: "50%",
        backgroundColor: color,
      }}
    />
  );
}

interface StatusLabelProps {
  label: string;
}

function StatusLabel({ label }: StatusLabelProps) {
  return (
    <span data-testid="health-label" style={{ fontWeight: 500 }}>
      {label}
    </span>
  );
}

interface StatusMessageProps {
  message: string;
}

function StatusMessage({ message }: StatusMessageProps) {
  return (
    <span data-testid="health-message" style={{ color: "#64748b" }}>
      - {message}
    </span>
  );
}
