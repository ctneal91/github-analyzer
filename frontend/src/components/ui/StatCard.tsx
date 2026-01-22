interface StatCardProps {
  testId: string;
  value: number | string;
  label: string;
}

export function StatCard({ testId, value, label }: StatCardProps) {
  return (
    <div className="stat-card" data-testid={testId}>
      <span className="stat-value">{value}</span>
      <span className="stat-label">{label}</span>
    </div>
  );
}
