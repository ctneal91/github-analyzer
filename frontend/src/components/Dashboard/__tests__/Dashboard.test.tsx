import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Dashboard } from "../Dashboard";
import * as api from "../../../api";

vi.mock("../../../api", () => ({
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

describe("Dashboard", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(api.getStats).mockResolvedValue(mockStats);
    vi.mocked(api.getRateLimit).mockResolvedValue(mockRateLimit);
  });

  it("shows loading state initially", () => {
    vi.mocked(api.getStats).mockImplementation(() => new Promise(() => {}));
    render(<Dashboard />);
    expect(screen.getByTestId("dashboard-loading")).toBeInTheDocument();
  });

  it("displays stats after loading", async () => {
    render(<Dashboard />);

    await waitFor(() => {
      expect(screen.getByTestId("dashboard")).toBeInTheDocument();
    });

    expect(screen.getByTestId("stat-total-events")).toHaveTextContent("100");
    expect(screen.getByTestId("stat-enriched-events")).toHaveTextContent("80");
    expect(screen.getByTestId("stat-unenriched-events")).toHaveTextContent("20");
    expect(screen.getByTestId("stat-total-actors")).toHaveTextContent("50");
    expect(screen.getByTestId("stat-total-repositories")).toHaveTextContent("30");
  });

  it("shows error state when fetch fails", async () => {
    vi.mocked(api.getStats).mockRejectedValue(new Error("Network error"));

    render(<Dashboard />);

    await waitFor(() => {
      expect(screen.getByTestId("dashboard-error")).toBeInTheDocument();
    });

    expect(screen.getByText(/Network error/)).toBeInTheDocument();
  });

  it("retries fetch on error retry button click", async () => {
    const user = userEvent.setup();
    vi.mocked(api.getStats)
      .mockRejectedValueOnce(new Error("Network error"))
      .mockResolvedValueOnce(mockStats);

    render(<Dashboard />);

    await waitFor(() => {
      expect(screen.getByTestId("dashboard-error")).toBeInTheDocument();
    });

    await user.click(screen.getByRole("button", { name: /retry/i }));

    await waitFor(() => {
      expect(screen.getByTestId("dashboard")).toBeInTheDocument();
    });

    expect(api.getStats).toHaveBeenCalledTimes(2);
  });

  it("displays the main title", async () => {
    render(<Dashboard />);

    await waitFor(() => {
      expect(screen.getByTestId("dashboard")).toBeInTheDocument();
    });

    expect(
      screen.getByRole("heading", { name: /github event analyzer/i })
    ).toBeInTheDocument();
  });

  it("includes RateLimitStatus component", async () => {
    render(<Dashboard />);

    await waitFor(() => {
      expect(screen.getByTestId("rate-limit-section")).toBeInTheDocument();
    });
  });

  it("includes AdminActions component", async () => {
    render(<Dashboard />);

    await waitFor(() => {
      expect(screen.getByTestId("admin-actions-section")).toBeInTheDocument();
    });
  });

  it("refreshes stats when admin operation completes", async () => {
    const user = userEvent.setup();
    vi.mocked(api.triggerIngest).mockResolvedValue({
      status: "completed",
      processed: 5,
      skipped: 1,
      errors: 0,
    });

    render(<Dashboard />);

    await waitFor(() => {
      expect(screen.getByTestId("dashboard")).toBeInTheDocument();
    });

    expect(api.getStats).toHaveBeenCalledTimes(1);

    await user.click(screen.getByTestId("btn-ingest"));

    await waitFor(() => {
      expect(api.getStats).toHaveBeenCalledTimes(2);
    });
  });
});
