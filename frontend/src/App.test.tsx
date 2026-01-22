import { render, screen, waitFor } from "@testing-library/react";
import { describe, it, expect, vi, beforeEach } from "vitest";
import App from "./App";
import * as api from "./api";

vi.mock("./api", () => ({
  getStats: vi.fn(),
  getRateLimit: vi.fn(),
  triggerIngest: vi.fn(),
  triggerEnrich: vi.fn(),
  triggerSync: vi.fn(),
}));

const mockStats = {
  total_events: 100,
  enriched_events: 80,
  unenriched_events: 20,
  total_actors: 50,
  total_repositories: 30,
};

const mockRateLimit = {
  remaining: 42,
  resets_at: "2024-01-01T12:00:00Z",
  can_make_requests: true,
  time_until_reset: 1800,
};

describe("App", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(api.getStats).mockResolvedValue(mockStats);
    vi.mocked(api.getRateLimit).mockResolvedValue(mockRateLimit);
  });

  it("renders the Dashboard component", async () => {
    render(<App />);

    await waitFor(() => {
      expect(screen.getByTestId("dashboard")).toBeInTheDocument();
    });
  });

  it("renders the main heading from Dashboard", async () => {
    render(<App />);

    await waitFor(() => {
      expect(
        screen.getByRole("heading", { name: /GitHub Event Analyzer/i })
      ).toBeInTheDocument();
    });
  });

  it("displays stats from the API", async () => {
    render(<App />);

    await waitFor(() => {
      expect(screen.getByTestId("stat-total-events")).toHaveTextContent("100");
    });
  });

  it("displays rate limit status", async () => {
    render(<App />);

    await waitFor(() => {
      expect(screen.getByTestId("rate-limit-section")).toBeInTheDocument();
    });
  });

  it("displays admin action buttons", async () => {
    render(<App />);

    await waitFor(() => {
      expect(screen.getByTestId("btn-ingest")).toBeInTheDocument();
      expect(screen.getByTestId("btn-enrich")).toBeInTheDocument();
      expect(screen.getByTestId("btn-sync")).toBeInTheDocument();
    });
  });
});
