import { useState, useEffect, useCallback } from "react";

interface AsyncDataState<T> {
  data: T | null;
  loading: boolean;
  error: string | null;
}

interface UseAsyncDataResult<T> extends AsyncDataState<T> {
  refetch: () => Promise<void>;
}

export function useAsyncData<T>(
  fetchFn: () => Promise<T>,
  dependencies: unknown[] = []
): UseAsyncDataResult<T> {
  const [state, setState] = useState<AsyncDataState<T>>({
    data: null,
    loading: true,
    error: null,
  });

  const fetch = useCallback(async () => {
    setState((prev) => ({ ...prev, loading: true, error: null }));
    try {
      const data = await fetchFn();
      setState({ data, loading: false, error: null });
    } catch (err) {
      const message = err instanceof Error ? err.message : "An error occurred";
      setState((prev) => ({ ...prev, loading: false, error: message }));
    }
  }, [fetchFn]);

  useEffect(() => {
    fetch();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, dependencies);

  return { ...state, refetch: fetch };
}
