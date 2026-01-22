import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { LoadingState, ErrorState, StatCard } from "../index";

describe("LoadingState", () => {
  it("renders with default props", () => {
    render(<LoadingState />);
    expect(screen.getByTestId("loading")).toHaveTextContent("Loading...");
  });

  it("renders with custom testId and message", () => {
    render(<LoadingState testId="custom-loading" message="Please wait..." />);
    expect(screen.getByTestId("custom-loading")).toHaveTextContent(
      "Please wait..."
    );
  });
});

describe("ErrorState", () => {
  it("renders error message", () => {
    render(<ErrorState message="Something went wrong" />);
    expect(screen.getByTestId("error")).toHaveTextContent("Something went wrong");
  });

  it("renders with custom testId", () => {
    render(<ErrorState testId="custom-error" message="Error" />);
    expect(screen.getByTestId("custom-error")).toBeInTheDocument();
  });

  it("renders retry button when onRetry is provided", async () => {
    const user = userEvent.setup();
    const onRetry = vi.fn();
    render(<ErrorState message="Error" onRetry={onRetry} />);

    const button = screen.getByRole("button", { name: /retry/i });
    await user.click(button);

    expect(onRetry).toHaveBeenCalledTimes(1);
  });

  it("does not render retry button when onRetry is not provided", () => {
    render(<ErrorState message="Error" />);
    expect(screen.queryByRole("button")).not.toBeInTheDocument();
  });
});

describe("StatCard", () => {
  it("renders value and label", () => {
    render(<StatCard testId="stat-test" value={42} label="Count" />);

    const card = screen.getByTestId("stat-test");
    expect(card).toHaveTextContent("42");
    expect(card).toHaveTextContent("Count");
  });

  it("renders string values", () => {
    render(<StatCard testId="stat-test" value="30m 0s" label="Time" />);

    expect(screen.getByTestId("stat-test")).toHaveTextContent("30m 0s");
  });
});
