import { describe, it, expect, vi } from "vitest";
import { renderHook, waitFor, act } from "@testing-library/react";
import { useAsyncData } from "./useAsyncData";

describe("useAsyncData", () => {
  it("starts in loading state", () => {
    const fetchFn = vi.fn(() => new Promise(() => {}));
    const { result } = renderHook(() => useAsyncData(fetchFn, []));

    expect(result.current.loading).toBe(true);
    expect(result.current.data).toBeNull();
    expect(result.current.error).toBeNull();
  });

  it("sets data on successful fetch", async () => {
    const mockData = { value: "test" };
    const fetchFn = vi.fn().mockResolvedValue(mockData);

    const { result } = renderHook(() => useAsyncData(fetchFn, []));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.data).toEqual(mockData);
    expect(result.current.error).toBeNull();
  });

  it("sets error on failed fetch", async () => {
    const fetchFn = vi.fn().mockRejectedValue(new Error("Fetch failed"));

    const { result } = renderHook(() => useAsyncData(fetchFn, []));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.data).toBeNull();
    expect(result.current.error).toBe("Fetch failed");
  });

  it("handles non-Error exceptions", async () => {
    const fetchFn = vi.fn().mockRejectedValue("string error");

    const { result } = renderHook(() => useAsyncData(fetchFn, []));

    await waitFor(() => {
      expect(result.current.loading).toBe(false);
    });

    expect(result.current.error).toBe("An error occurred");
  });

  it("refetches data when refetch is called", async () => {
    const fetchFn = vi
      .fn()
      .mockResolvedValueOnce({ value: 1 })
      .mockResolvedValueOnce({ value: 2 });

    const { result } = renderHook(() => useAsyncData(fetchFn, []));

    await waitFor(() => {
      expect(result.current.data).toEqual({ value: 1 });
    });

    await act(async () => {
      await result.current.refetch();
    });

    await waitFor(() => {
      expect(result.current.data).toEqual({ value: 2 });
    });

    expect(fetchFn).toHaveBeenCalledTimes(2);
  });

  it("preserves previous data during refetch", async () => {
    const fetchFn = vi
      .fn()
      .mockResolvedValueOnce({ value: 1 })
      .mockImplementationOnce(() => new Promise(() => {}));

    const { result } = renderHook(() => useAsyncData(fetchFn, []));

    await waitFor(() => {
      expect(result.current.data).toEqual({ value: 1 });
    });

    act(() => {
      result.current.refetch();
    });

    await waitFor(() => {
      expect(result.current.loading).toBe(true);
    });

    expect(result.current.data).toEqual({ value: 1 });
  });
});
