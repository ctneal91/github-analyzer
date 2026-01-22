import { render, screen } from "@testing-library/react";
import { describe, it, expect } from "vitest";
import { HealthStatus } from "../HealthStatus";

describe("HealthStatus", () => {
  it("renders healthy status correctly", () => {
    render(<HealthStatus status="healthy" />);

    expect(screen.getByTestId("health-status")).toBeInTheDocument();
    expect(screen.getByTestId("health-label")).toHaveTextContent("Healthy");
  });

  it("renders unhealthy status correctly", () => {
    render(<HealthStatus status="unhealthy" />);

    expect(screen.getByTestId("health-label")).toHaveTextContent("Unhealthy");
  });

  it("renders loading status correctly", () => {
    render(<HealthStatus status="loading" />);

    expect(screen.getByTestId("health-label")).toHaveTextContent("Loading...");
  });

  it("displays message when provided", () => {
    render(<HealthStatus status="healthy" message="All systems operational" />);

    expect(screen.getByTestId("health-message")).toHaveTextContent(
      "- All systems operational"
    );
  });

  it("does not display message when not provided", () => {
    render(<HealthStatus status="healthy" />);

    expect(screen.queryByTestId("health-message")).not.toBeInTheDocument();
  });

  it("applies correct color for healthy status", () => {
    render(<HealthStatus status="healthy" />);

    const indicator = screen.getByTestId("health-indicator");
    expect(indicator).toHaveStyle({ backgroundColor: "#22c55e" });
  });

  it("applies correct color for unhealthy status", () => {
    render(<HealthStatus status="unhealthy" />);

    const indicator = screen.getByTestId("health-indicator");
    expect(indicator).toHaveStyle({ backgroundColor: "#ef4444" });
  });

  it("applies correct color for loading status", () => {
    render(<HealthStatus status="loading" />);

    const indicator = screen.getByTestId("health-indicator");
    expect(indicator).toHaveStyle({ backgroundColor: "#f59e0b" });
  });
});
