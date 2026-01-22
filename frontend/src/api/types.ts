// Actor types
export interface ActorSummary {
  id: number;
  github_id: number;
  login: string;
  avatar_url: string;
}

export interface Actor extends ActorSummary {
  event_count: number;
  created_at: string;
}

// Repository types
export interface RepositorySummary {
  id: number;
  github_id: number;
  name: string;
  full_name: string;
}

export interface Repository extends RepositorySummary {
  event_count: number;
  created_at: string;
}

// Event types
export interface Event {
  id: number;
  github_event_id: string;
  push_id: number;
  ref: string;
  head: string;
  before: string;
  enriched: boolean;
  enriched_at: string | null;
  created_at: string;
  actor: ActorSummary | null;
  repository: RepositorySummary | null;
}

export interface EventDetail extends Event {
  raw_payload: Record<string, unknown>;
}

// Pagination meta
export interface PaginationMeta {
  total: number;
  limit: number;
  offset: number;
}

// List responses
export interface PaginatedResponse<T> {
  data: T[];
  meta: PaginationMeta;
}

// Stats response
export interface Stats {
  total_events: number;
  enriched_events: number;
  unenriched_events: number;
  total_actors: number;
  total_repositories: number;
}

// Rate limit response
export interface RateLimit {
  remaining: number;
  resets_at: string;
  can_make_requests: boolean;
  time_until_reset: number;
}

// Admin operation results
export interface ServiceResult {
  processed: number;
  skipped: number;
  errors: number;
}

export interface AdminResponse extends ServiceResult {
  status: "completed" | "rate_limited";
}

export interface SyncResponse {
  status: "completed" | "rate_limited";
  ingestion: ServiceResult;
  enrichment: ServiceResult;
}

// Error response
export interface ApiError {
  error: string;
  status?: string;
  resets_at?: string;
}

// Pagination params
export interface PaginationParams {
  limit?: number;
  offset?: number;
}
