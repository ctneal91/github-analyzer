import { useCallback } from "react";
import type { RateLimit } from "../../api";
import { getRateLimit } from "../../api";
import { useAsyncData, usePolling } from "../../hooks";
import { formatTimeUntilReset } from "../../utils";
import { LoadingState, ErrorState, StatCard } from "../ui";

const POLLING_INTERVAL_MS = 60000;

export function RateLimitStatus() {
  const fetchRateLimit = useCallback(() => getRateLimit(), []);
  const { data: rateLimit, loading, error, refetch } = useAsyncData(fetchRateLimit, []);

  usePolling(refetch, POLLING_INTERVAL_MS);

  if (loading && !rateLimit) {
    return <LoadingState testId="rate-limit-loading" message="Loading rate limit..." />;
  }

  if (error && !rateLimit) {
    return (
      <ErrorState
        testId="rate-limit-error"
        message={`Rate limit error: ${error}`}
        onRetry={refetch}
      />
    );
  }

  if (!rateLimit) return null;

  return (
    <section data-testid="rate-limit-section">
      <h2>GitHub API Rate Limit</h2>
      <RateLimitDisplay rateLimit={rateLimit} />
    </section>
  );
}

interface RateLimitDisplayProps {
  rateLimit: RateLimit;
}

function RateLimitDisplay({ rateLimit }: RateLimitDisplayProps) {
  const { remaining, can_make_requests, time_until_reset } = rateLimit;
  const statusClass = can_make_requests ? "status-ok" : "status-limited";
  const statusText = can_make_requests ? "Available" : "Rate Limited";

  return (
    <div className={`rate-limit-status ${statusClass}`}>
      <StatCard
        testId="rate-limit-remaining"
        value={remaining}
        label="Requests Remaining"
      />
      <StatCard
        testId="rate-limit-reset"
        value={formatTimeUntilReset(time_until_reset)}
        label="Until Reset"
      />
      <div data-testid="rate-limit-can-request">
        <span className={`status-indicator ${statusClass}`}>{statusText}</span>
      </div>
    </div>
  );
}
