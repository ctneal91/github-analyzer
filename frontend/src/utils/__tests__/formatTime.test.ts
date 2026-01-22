import { describe, it, expect } from "vitest";
import { formatTimeUntilReset } from "../formatTime";

describe("formatTimeUntilReset", () => {
  it("returns 'now' for zero seconds", () => {
    expect(formatTimeUntilReset(0)).toBe("now");
  });

  it("returns 'now' for negative seconds", () => {
    expect(formatTimeUntilReset(-10)).toBe("now");
  });

  it("formats seconds only when under a minute", () => {
    expect(formatTimeUntilReset(45)).toBe("45s");
    expect(formatTimeUntilReset(1)).toBe("1s");
    expect(formatTimeUntilReset(59)).toBe("59s");
  });

  it("formats minutes and seconds", () => {
    expect(formatTimeUntilReset(60)).toBe("1m 0s");
    expect(formatTimeUntilReset(90)).toBe("1m 30s");
    expect(formatTimeUntilReset(1800)).toBe("30m 0s");
    expect(formatTimeUntilReset(3599)).toBe("59m 59s");
  });

  it("formats hours as minutes", () => {
    expect(formatTimeUntilReset(3600)).toBe("60m 0s");
    expect(formatTimeUntilReset(7200)).toBe("120m 0s");
  });
});
