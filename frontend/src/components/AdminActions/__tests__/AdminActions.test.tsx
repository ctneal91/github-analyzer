import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { AdminActions } from "../AdminActions";
import * as api from "../../../api";

vi.mock("../../../api", () => ({
  triggerIngest: vi.fn(),
  triggerEnrich: vi.fn(),
  triggerSync: vi.fn(),
}));

describe("AdminActions", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("renders all action buttons", () => {
    render(<AdminActions />);

    expect(screen.getByTestId("btn-ingest")).toBeInTheDocument();
    expect(screen.getByTestId("btn-enrich")).toBeInTheDocument();
    expect(screen.getByTestId("btn-sync")).toBeInTheDocument();
  });

  it("shows loading state during ingest", async () => {
    const user = userEvent.setup();
    vi.mocked(api.triggerIngest).mockImplementation(
      () => new Promise(() => {})
    );

    render(<AdminActions />);

    await user.click(screen.getByTestId("btn-ingest"));

    expect(screen.getByTestId("btn-ingest")).toHaveTextContent("Ingesting...");
    expect(screen.getByTestId("btn-ingest")).toBeDisabled();
    expect(screen.getByTestId("btn-enrich")).toBeDisabled();
    expect(screen.getByTestId("btn-sync")).toBeDisabled();
  });

  it("shows loading state during enrich", async () => {
    const user = userEvent.setup();
    vi.mocked(api.triggerEnrich).mockImplementation(
      () => new Promise(() => {})
    );

    render(<AdminActions />);

    await user.click(screen.getByTestId("btn-enrich"));

    expect(screen.getByTestId("btn-enrich")).toHaveTextContent("Enriching...");
  });

  it("shows loading state during sync", async () => {
    const user = userEvent.setup();
    vi.mocked(api.triggerSync).mockImplementation(
      () => new Promise(() => {})
    );

    render(<AdminActions />);

    await user.click(screen.getByTestId("btn-sync"));

    expect(screen.getByTestId("btn-sync")).toHaveTextContent("Syncing...");
  });

  it("displays ingest result", async () => {
    const user = userEvent.setup();
    vi.mocked(api.triggerIngest).mockResolvedValue({
      status: "completed",
      processed: 10,
      skipped: 2,
      errors: 1,
    });

    render(<AdminActions />);

    await user.click(screen.getByTestId("btn-ingest"));

    await waitFor(() => {
      expect(screen.getByTestId("operation-result")).toBeInTheDocument();
    });

    expect(screen.getByTestId("operation-result")).toHaveTextContent(
      "10 processed"
    );
    expect(screen.getByTestId("operation-result")).toHaveTextContent(
      "2 skipped"
    );
    expect(screen.getByTestId("operation-result")).toHaveTextContent("1 errors");
  });

  it("displays enrich result", async () => {
    const user = userEvent.setup();
    vi.mocked(api.triggerEnrich).mockResolvedValue({
      status: "completed",
      processed: 5,
      skipped: 0,
      errors: 0,
    });

    render(<AdminActions />);

    await user.click(screen.getByTestId("btn-enrich"));

    await waitFor(() => {
      expect(screen.getByTestId("operation-result")).toBeInTheDocument();
    });

    expect(screen.getByTestId("operation-result")).toHaveTextContent(
      "5 processed"
    );
  });

  it("displays sync result with both ingestion and enrichment", async () => {
    const user = userEvent.setup();
    vi.mocked(api.triggerSync).mockResolvedValue({
      status: "completed",
      ingestion: { processed: 10, skipped: 2, errors: 0 },
      enrichment: { processed: 8, skipped: 1, errors: 1 },
    });

    render(<AdminActions />);

    await user.click(screen.getByTestId("btn-sync"));

    await waitFor(() => {
      expect(screen.getByTestId("operation-result")).toBeInTheDocument();
    });

    const result = screen.getByTestId("operation-result");
    expect(result).toHaveTextContent("Sync Complete");
    expect(result).toHaveTextContent("Ingestion: 10 processed");
    expect(result).toHaveTextContent("Enrichment: 8 processed");
  });

  it("displays error when operation fails", async () => {
    const user = userEvent.setup();
    vi.mocked(api.triggerIngest).mockRejectedValue(new Error("API error"));

    render(<AdminActions />);

    await user.click(screen.getByTestId("btn-ingest"));

    await waitFor(() => {
      expect(screen.getByTestId("operation-error")).toBeInTheDocument();
    });

    expect(screen.getByTestId("operation-error")).toHaveTextContent("API error");
  });

  it("calls onOperationComplete callback after successful operation", async () => {
    const user = userEvent.setup();
    const onComplete = vi.fn();
    vi.mocked(api.triggerIngest).mockResolvedValue({
      status: "completed",
      processed: 5,
      skipped: 0,
      errors: 0,
    });

    render(<AdminActions onOperationComplete={onComplete} />);

    await user.click(screen.getByTestId("btn-ingest"));

    await waitFor(() => {
      expect(onComplete).toHaveBeenCalledTimes(1);
    });
  });

  it("does not call onOperationComplete on error", async () => {
    const user = userEvent.setup();
    const onComplete = vi.fn();
    vi.mocked(api.triggerIngest).mockRejectedValue(new Error("API error"));

    render(<AdminActions onOperationComplete={onComplete} />);

    await user.click(screen.getByTestId("btn-ingest"));

    await waitFor(() => {
      expect(screen.getByTestId("operation-error")).toBeInTheDocument();
    });

    expect(onComplete).not.toHaveBeenCalled();
  });

  it("re-enables buttons after operation completes", async () => {
    const user = userEvent.setup();
    vi.mocked(api.triggerIngest).mockResolvedValue({
      status: "completed",
      processed: 5,
      skipped: 0,
      errors: 0,
    });

    render(<AdminActions />);

    await user.click(screen.getByTestId("btn-ingest"));

    await waitFor(() => {
      expect(screen.getByTestId("operation-result")).toBeInTheDocument();
    });

    expect(screen.getByTestId("btn-ingest")).not.toBeDisabled();
    expect(screen.getByTestId("btn-enrich")).not.toBeDisabled();
    expect(screen.getByTestId("btn-sync")).not.toBeDisabled();
  });

  it("handles non-Error exceptions gracefully", async () => {
    const user = userEvent.setup();
    vi.mocked(api.triggerIngest).mockRejectedValue("string error");

    render(<AdminActions />);

    await user.click(screen.getByTestId("btn-ingest"));

    await waitFor(() => {
      expect(screen.getByTestId("operation-error")).toBeInTheDocument();
    });

    expect(screen.getByTestId("operation-error")).toHaveTextContent(
      "Operation failed"
    );
  });
});
