import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen, waitFor, act } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { RateLimitStatus } from "../RateLimitStatus";
import * as api from "../../../api";

vi.mock("../../../api", () => ({
  getRateLimit: vi.fn(),
}));

const mockRateLimit = {
  remaining: 42,
  resets_at: "2024-01-01T12:00:00Z",
  can_make_requests: true,
  time_until_reset: 1800,
};

describe("RateLimitStatus", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(api.getRateLimit).mockResolvedValue(mockRateLimit);
  });

  it("shows loading state initially", () => {
    vi.mocked(api.getRateLimit).mockImplementation(() => new Promise(() => {}));
    render(<RateLimitStatus />);
    expect(screen.getByTestId("rate-limit-loading")).toBeInTheDocument();
  });

  it("displays rate limit info after loading", async () => {
    render(<RateLimitStatus />);

    await waitFor(() => {
      expect(screen.getByTestId("rate-limit-section")).toBeInTheDocument();
    });

    expect(screen.getByTestId("rate-limit-remaining")).toHaveTextContent("42");
    expect(screen.getByTestId("rate-limit-reset")).toHaveTextContent("30m 0s");
    expect(screen.getByTestId("rate-limit-can-request")).toHaveTextContent(
      "Available"
    );
  });

  it("shows error state when fetch fails", async () => {
    vi.mocked(api.getRateLimit).mockRejectedValue(new Error("API error"));

    render(<RateLimitStatus />);

    await waitFor(() => {
      expect(screen.getByTestId("rate-limit-error")).toBeInTheDocument();
    });

    expect(screen.getByText(/API error/)).toBeInTheDocument();
  });

  it("retries fetch on error retry button click", async () => {
    const user = userEvent.setup();
    vi.mocked(api.getRateLimit)
      .mockRejectedValueOnce(new Error("API error"))
      .mockResolvedValueOnce(mockRateLimit);

    render(<RateLimitStatus />);

    await waitFor(() => {
      expect(screen.getByTestId("rate-limit-error")).toBeInTheDocument();
    });

    await user.click(screen.getByRole("button", { name: /retry/i }));

    await waitFor(() => {
      expect(screen.getByTestId("rate-limit-section")).toBeInTheDocument();
    });

    expect(api.getRateLimit).toHaveBeenCalledTimes(2);
  });

  it("shows Rate Limited status when cannot make requests", async () => {
    vi.mocked(api.getRateLimit).mockResolvedValue({
      ...mockRateLimit,
      can_make_requests: false,
      remaining: 0,
    });

    render(<RateLimitStatus />);

    await waitFor(() => {
      expect(screen.getByTestId("rate-limit-section")).toBeInTheDocument();
    });

    expect(screen.getByTestId("rate-limit-can-request")).toHaveTextContent(
      "Rate Limited"
    );
  });

  it("formats time correctly for seconds only", async () => {
    vi.mocked(api.getRateLimit).mockResolvedValue({
      ...mockRateLimit,
      time_until_reset: 45,
    });

    render(<RateLimitStatus />);

    await waitFor(() => {
      expect(screen.getByTestId("rate-limit-reset")).toHaveTextContent("45s");
    });
  });

  it("formats time correctly for zero seconds", async () => {
    vi.mocked(api.getRateLimit).mockResolvedValue({
      ...mockRateLimit,
      time_until_reset: 0,
    });

    render(<RateLimitStatus />);

    await waitFor(() => {
      expect(screen.getByTestId("rate-limit-reset")).toHaveTextContent("now");
    });
  });

  describe("polling behavior", () => {
    beforeEach(() => {
      vi.useFakeTimers({ shouldAdvanceTime: true });
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it("polls for updates every minute", async () => {
      render(<RateLimitStatus />);

      await waitFor(() => {
        expect(screen.getByTestId("rate-limit-section")).toBeInTheDocument();
      });

      expect(api.getRateLimit).toHaveBeenCalledTimes(1);

      await act(async () => {
        vi.advanceTimersByTime(60000);
      });

      await waitFor(() => {
        expect(api.getRateLimit).toHaveBeenCalledTimes(2);
      });
    });

    it("clears interval on unmount", async () => {
      const { unmount } = render(<RateLimitStatus />);

      await waitFor(() => {
        expect(screen.getByTestId("rate-limit-section")).toBeInTheDocument();
      });

      unmount();

      await act(async () => {
        vi.advanceTimersByTime(60000);
      });

      expect(api.getRateLimit).toHaveBeenCalledTimes(1);
    });
  });
});
