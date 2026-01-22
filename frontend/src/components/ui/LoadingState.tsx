interface LoadingStateProps {
  testId?: string;
  message?: string;
}

export function LoadingState({
  testId = "loading",
  message = "Loading...",
}: LoadingStateProps) {
  return <div data-testid={testId}>{message}</div>;
}
