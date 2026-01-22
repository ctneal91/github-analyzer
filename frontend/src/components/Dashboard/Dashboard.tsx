import { useCallback } from "react";
import { getStats } from "../../api";
import { useAsyncData } from "../../hooks";
import { LoadingState, ErrorState, StatCard } from "../ui";
import { RateLimitStatus } from "../RateLimitStatus";
import { AdminActions } from "../AdminActions";

export function Dashboard() {
  const fetchStats = useCallback(() => getStats(), []);
  const { data: stats, loading, error, refetch } = useAsyncData(fetchStats, []);

  if (loading && !stats) {
    return <LoadingState testId="dashboard-loading" message="Loading dashboard..." />;
  }

  if (error && !stats) {
    return <ErrorState testId="dashboard-error" message={error} onRetry={refetch} />;
  }

  return (
    <div data-testid="dashboard">
      <h1>GitHub Event Analyzer</h1>

      <StatsSection stats={stats} />
      <RateLimitStatus />
      <AdminActions onOperationComplete={refetch} />
    </div>
  );
}

interface StatsSectionProps {
  stats: {
    total_events: number;
    enriched_events: number;
    unenriched_events: number;
    total_actors: number;
    total_repositories: number;
  } | null;
}

function StatsSection({ stats }: StatsSectionProps) {
  if (!stats) return null;

  return (
    <section data-testid="stats-section">
      <h2>Statistics</h2>
      <div className="stats-grid">
        <StatCard testId="stat-total-events" value={stats.total_events} label="Total Events" />
        <StatCard testId="stat-enriched-events" value={stats.enriched_events} label="Enriched" />
        <StatCard testId="stat-unenriched-events" value={stats.unenriched_events} label="Unenriched" />
        <StatCard testId="stat-total-actors" value={stats.total_actors} label="Actors" />
        <StatCard testId="stat-total-repositories" value={stats.total_repositories} label="Repositories" />
      </div>
    </section>
  );
}
