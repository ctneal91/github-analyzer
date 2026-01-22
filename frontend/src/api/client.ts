import type {
  Actor,
  AdminResponse,
  ApiError,
  Event,
  EventDetail,
  PaginatedResponse,
  PaginationParams,
  RateLimit,
  Repository,
  Stats,
  SyncResponse,
} from "./types";

const API_BASE_URL = import.meta.env.VITE_API_URL || "http://localhost:3000";

class ApiClientError extends Error {
  constructor(
    message: string,
    public status: number,
    public data?: ApiError
  ) {
    super(message);
    this.name = "ApiClientError";
  }
}

async function request<T>(endpoint: string, options?: RequestInit): Promise<T> {
  const url = `${API_BASE_URL}${endpoint}`;
  const response = await fetch(url, {
    ...options,
    headers: {
      "Content-Type": "application/json",
      ...options?.headers,
    },
  });

  if (!response.ok) {
    const errorData = (await response.json().catch(() => ({}))) as ApiError;
    throw new ApiClientError(
      errorData.error || `Request failed with status ${response.status}`,
      response.status,
      errorData
    );
  }

  return response.json() as Promise<T>;
}

function buildQueryString(params: PaginationParams): string {
  const searchParams = new URLSearchParams();
  if (params.limit !== undefined) {
    searchParams.set("limit", params.limit.toString());
  }
  if (params.offset !== undefined) {
    searchParams.set("offset", params.offset.toString());
  }
  const queryString = searchParams.toString();
  return queryString ? `?${queryString}` : "";
}

// Stats endpoints
export function getStats(): Promise<Stats> {
  return request<Stats>("/api/v1/stats");
}

export function getRateLimit(): Promise<RateLimit> {
  return request<RateLimit>("/api/v1/rate_limit");
}

// Events endpoints
export function getEvents(
  params: PaginationParams = {}
): Promise<PaginatedResponse<Event>> {
  return request<PaginatedResponse<Event>>(
    `/api/v1/events${buildQueryString(params)}`
  );
}

export function getEvent(id: number): Promise<EventDetail> {
  return request<EventDetail>(`/api/v1/events/${id}`);
}

// Actors endpoints
export function getActors(
  params: PaginationParams = {}
): Promise<PaginatedResponse<Actor>> {
  return request<PaginatedResponse<Actor>>(
    `/api/v1/actors${buildQueryString(params)}`
  );
}

// Repositories endpoints
export function getRepositories(
  params: PaginationParams = {}
): Promise<PaginatedResponse<Repository>> {
  return request<PaginatedResponse<Repository>>(
    `/api/v1/repositories${buildQueryString(params)}`
  );
}

// Admin endpoints
export function triggerIngest(): Promise<AdminResponse> {
  return request<AdminResponse>("/api/v1/admin/ingest", { method: "POST" });
}

export function triggerEnrich(): Promise<AdminResponse> {
  return request<AdminResponse>("/api/v1/admin/enrich", { method: "POST" });
}

export function triggerSync(): Promise<SyncResponse> {
  return request<SyncResponse>("/api/v1/admin/sync", { method: "POST" });
}

export { ApiClientError };
