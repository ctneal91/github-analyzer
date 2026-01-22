import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import {
  getStats,
  getRateLimit,
  getEvents,
  getEvent,
  getActors,
  getRepositories,
  triggerIngest,
  triggerEnrich,
  triggerSync,
  ApiClientError,
} from "./client";

const mockFetch = vi.fn();
vi.stubGlobal("fetch", mockFetch);

describe("API Client", () => {
  beforeEach(() => {
    mockFetch.mockReset();
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  function mockSuccessResponse<T>(data: T) {
    mockFetch.mockResolvedValueOnce({
      ok: true,
      json: () => Promise.resolve(data),
    });
  }

  function mockErrorResponse(status: number, data: Record<string, unknown>) {
    mockFetch.mockResolvedValueOnce({
      ok: false,
      status,
      json: () => Promise.resolve(data),
    });
  }

  describe("getStats", () => {
    it("fetches stats from the API", async () => {
      const mockStats = {
        total_events: 100,
        enriched_events: 80,
        unenriched_events: 20,
        total_actors: 50,
        total_repositories: 30,
      };
      mockSuccessResponse(mockStats);

      const result = await getStats();

      expect(result).toEqual(mockStats);
      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/stats",
        expect.objectContaining({
          headers: { "Content-Type": "application/json" },
        })
      );
    });
  });

  describe("getRateLimit", () => {
    it("fetches rate limit status from the API", async () => {
      const mockRateLimit = {
        remaining: 42,
        resets_at: "2024-01-01T12:00:00Z",
        can_make_requests: true,
        time_until_reset: 1800,
      };
      mockSuccessResponse(mockRateLimit);

      const result = await getRateLimit();

      expect(result).toEqual(mockRateLimit);
      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/rate_limit",
        expect.any(Object)
      );
    });
  });

  describe("getEvents", () => {
    it("fetches events without pagination params", async () => {
      const mockEvents = {
        data: [{ id: 1, github_event_id: "abc123" }],
        meta: { total: 1, limit: 50, offset: 0 },
      };
      mockSuccessResponse(mockEvents);

      const result = await getEvents();

      expect(result).toEqual(mockEvents);
      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/events",
        expect.any(Object)
      );
    });

    it("fetches events with pagination params", async () => {
      const mockEvents = {
        data: [],
        meta: { total: 100, limit: 10, offset: 20 },
      };
      mockSuccessResponse(mockEvents);

      const result = await getEvents({ limit: 10, offset: 20 });

      expect(result).toEqual(mockEvents);
      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/events?limit=10&offset=20",
        expect.any(Object)
      );
    });

    it("fetches events with only limit param", async () => {
      const mockEvents = {
        data: [],
        meta: { total: 100, limit: 5, offset: 0 },
      };
      mockSuccessResponse(mockEvents);

      await getEvents({ limit: 5 });

      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/events?limit=5",
        expect.any(Object)
      );
    });

    it("fetches events with only offset param", async () => {
      const mockEvents = {
        data: [],
        meta: { total: 100, limit: 50, offset: 10 },
      };
      mockSuccessResponse(mockEvents);

      await getEvents({ offset: 10 });

      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/events?offset=10",
        expect.any(Object)
      );
    });
  });

  describe("getEvent", () => {
    it("fetches a single event by id", async () => {
      const mockEvent = {
        id: 1,
        github_event_id: "abc123",
        raw_payload: { test: "data" },
      };
      mockSuccessResponse(mockEvent);

      const result = await getEvent(1);

      expect(result).toEqual(mockEvent);
      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/events/1",
        expect.any(Object)
      );
    });
  });

  describe("getActors", () => {
    it("fetches actors without pagination params", async () => {
      const mockActors = {
        data: [{ id: 1, login: "testuser" }],
        meta: { total: 1, limit: 50, offset: 0 },
      };
      mockSuccessResponse(mockActors);

      const result = await getActors();

      expect(result).toEqual(mockActors);
      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/actors",
        expect.any(Object)
      );
    });

    it("fetches actors with pagination params", async () => {
      const mockActors = {
        data: [],
        meta: { total: 50, limit: 10, offset: 5 },
      };
      mockSuccessResponse(mockActors);

      const result = await getActors({ limit: 10, offset: 5 });

      expect(result).toEqual(mockActors);
      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/actors?limit=10&offset=5",
        expect.any(Object)
      );
    });
  });

  describe("getRepositories", () => {
    it("fetches repositories without pagination params", async () => {
      const mockRepos = {
        data: [{ id: 1, name: "test-repo" }],
        meta: { total: 1, limit: 50, offset: 0 },
      };
      mockSuccessResponse(mockRepos);

      const result = await getRepositories();

      expect(result).toEqual(mockRepos);
      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/repositories",
        expect.any(Object)
      );
    });

    it("fetches repositories with pagination params", async () => {
      const mockRepos = {
        data: [],
        meta: { total: 30, limit: 15, offset: 0 },
      };
      mockSuccessResponse(mockRepos);

      const result = await getRepositories({ limit: 15 });

      expect(result).toEqual(mockRepos);
      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/repositories?limit=15",
        expect.any(Object)
      );
    });
  });

  describe("triggerIngest", () => {
    it("triggers ingest and returns result", async () => {
      const mockResult = {
        status: "completed",
        processed: 10,
        skipped: 2,
        errors: 0,
      };
      mockSuccessResponse(mockResult);

      const result = await triggerIngest();

      expect(result).toEqual(mockResult);
      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/admin/ingest",
        expect.objectContaining({ method: "POST" })
      );
    });
  });

  describe("triggerEnrich", () => {
    it("triggers enrich and returns result", async () => {
      const mockResult = {
        status: "completed",
        processed: 5,
        skipped: 0,
        errors: 1,
      };
      mockSuccessResponse(mockResult);

      const result = await triggerEnrich();

      expect(result).toEqual(mockResult);
      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/admin/enrich",
        expect.objectContaining({ method: "POST" })
      );
    });
  });

  describe("triggerSync", () => {
    it("triggers sync and returns combined result", async () => {
      const mockResult = {
        status: "completed",
        ingestion: { processed: 10, skipped: 2, errors: 0 },
        enrichment: { processed: 8, skipped: 0, errors: 0 },
      };
      mockSuccessResponse(mockResult);

      const result = await triggerSync();

      expect(result).toEqual(mockResult);
      expect(mockFetch).toHaveBeenCalledWith(
        "http://localhost:3000/api/v1/admin/sync",
        expect.objectContaining({ method: "POST" })
      );
    });
  });

  describe("error handling", () => {
    it("throws ApiClientError on 404", async () => {
      mockErrorResponse(404, { error: "Not found" });

      try {
        await getEvent(999);
        expect.fail("Should have thrown");
      } catch (error) {
        expect(error).toBeInstanceOf(ApiClientError);
        expect((error as ApiClientError).message).toBe("Not found");
        expect((error as ApiClientError).status).toBe(404);
      }
    });

    it("throws ApiClientError on 429 rate limit", async () => {
      mockErrorResponse(429, {
        status: "rate_limited",
        error: "GitHub API rate limit exceeded",
        resets_at: "2024-01-01T12:00:00Z",
      });

      try {
        await triggerIngest();
        expect.fail("Should have thrown");
      } catch (error) {
        expect(error).toBeInstanceOf(ApiClientError);
        expect((error as ApiClientError).status).toBe(429);
        expect((error as ApiClientError).data?.status).toBe("rate_limited");
      }
    });

    it("handles JSON parse errors gracefully", async () => {
      mockFetch.mockResolvedValueOnce({
        ok: false,
        status: 500,
        json: () => Promise.reject(new Error("Invalid JSON")),
      });

      try {
        await getStats();
        expect.fail("Should have thrown");
      } catch (error) {
        expect(error).toBeInstanceOf(ApiClientError);
        expect((error as ApiClientError).message).toBe(
          "Request failed with status 500"
        );
        expect((error as ApiClientError).status).toBe(500);
      }
    });
  });
});
