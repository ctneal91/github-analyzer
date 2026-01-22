interface ErrorStateProps {
  testId?: string;
  message: string;
  onRetry?: () => void;
}

export function ErrorState({ testId = "error", message, onRetry }: ErrorStateProps) {
  return (
    <div data-testid={testId}>
      <p>Error: {message}</p>
      {onRetry && <button onClick={onRetry}>Retry</button>}
    </div>
  );
}
