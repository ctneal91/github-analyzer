import { useState, useCallback } from "react";
import type { AdminResponse, SyncResponse, ServiceResult } from "../../api";
import { triggerIngest, triggerEnrich, triggerSync } from "../../api";

interface AdminActionsProps {
  onOperationComplete?: () => void;
}

type OperationType = "ingest" | "enrich" | "sync";
type OperationResult = AdminResponse | SyncResponse;

interface OperationState {
  activeOperation: OperationType | null;
  result: OperationResult | null;
  error: string | null;
}

const INITIAL_STATE: OperationState = {
  activeOperation: null,
  result: null,
  error: null,
};

export function AdminActions({ onOperationComplete }: AdminActionsProps) {
  const [state, setState] = useState<OperationState>(INITIAL_STATE);

  const executeOperation = useCallback(
    async (operation: OperationType, fn: () => Promise<OperationResult>) => {
      setState({ activeOperation: operation, result: null, error: null });
      try {
        const result = await fn();
        setState({ activeOperation: null, result, error: null });
        onOperationComplete?.();
      } catch (err) {
        const message = err instanceof Error ? err.message : "Operation failed";
        setState({ activeOperation: null, result: null, error: message });
      }
    },
    [onOperationComplete]
  );

  const isDisabled = state.activeOperation !== null;

  return (
    <section data-testid="admin-actions-section">
      <h2>Actions</h2>
      <ActionButtons
        activeOperation={state.activeOperation}
        disabled={isDisabled}
        onIngest={() => executeOperation("ingest", triggerIngest)}
        onEnrich={() => executeOperation("enrich", triggerEnrich)}
        onSync={() => executeOperation("sync", triggerSync)}
      />
      <OperationFeedback error={state.error} result={state.result} />
    </section>
  );
}

interface ActionButtonsProps {
  activeOperation: OperationType | null;
  disabled: boolean;
  onIngest: () => void;
  onEnrich: () => void;
  onSync: () => void;
}

function ActionButtons({
  activeOperation,
  disabled,
  onIngest,
  onEnrich,
  onSync,
}: ActionButtonsProps) {
  return (
    <div className="action-buttons">
      <ActionButton
        testId="btn-ingest"
        label="Ingest Events"
        loadingLabel="Ingesting..."
        isLoading={activeOperation === "ingest"}
        disabled={disabled}
        onClick={onIngest}
      />
      <ActionButton
        testId="btn-enrich"
        label="Enrich Events"
        loadingLabel="Enriching..."
        isLoading={activeOperation === "enrich"}
        disabled={disabled}
        onClick={onEnrich}
      />
      <ActionButton
        testId="btn-sync"
        label="Full Sync"
        loadingLabel="Syncing..."
        isLoading={activeOperation === "sync"}
        disabled={disabled}
        onClick={onSync}
      />
    </div>
  );
}

interface ActionButtonProps {
  testId: string;
  label: string;
  loadingLabel: string;
  isLoading: boolean;
  disabled: boolean;
  onClick: () => void;
}

function ActionButton({
  testId,
  label,
  loadingLabel,
  isLoading,
  disabled,
  onClick,
}: ActionButtonProps) {
  return (
    <button onClick={onClick} disabled={disabled} data-testid={testId}>
      {isLoading ? loadingLabel : label}
    </button>
  );
}

interface OperationFeedbackProps {
  error: string | null;
  result: OperationResult | null;
}

function OperationFeedback({ error, result }: OperationFeedbackProps) {
  if (error) {
    return (
      <div className="operation-error" data-testid="operation-error">
        Error: {error}
      </div>
    );
  }

  if (!result) return null;

  if (isSyncResponse(result)) {
    return <SyncResultDisplay result={result} />;
  }

  return <AdminResultDisplay result={result} />;
}

function isSyncResponse(result: OperationResult): result is SyncResponse {
  return "ingestion" in result;
}

interface SyncResultDisplayProps {
  result: SyncResponse;
}

function SyncResultDisplay({ result }: SyncResultDisplayProps) {
  return (
    <div className="operation-result" data-testid="operation-result">
      <h4>Sync Complete</h4>
      <ServiceResultLine label="Ingestion" result={result.ingestion} />
      <ServiceResultLine label="Enrichment" result={result.enrichment} />
    </div>
  );
}

interface AdminResultDisplayProps {
  result: AdminResponse;
}

function AdminResultDisplay({ result }: AdminResultDisplayProps) {
  return (
    <div className="operation-result" data-testid="operation-result">
      <h4>Operation Complete</h4>
      <p>
        {result.processed} processed, {result.skipped} skipped, {result.errors} errors
      </p>
    </div>
  );
}

interface ServiceResultLineProps {
  label: string;
  result: ServiceResult;
}

function ServiceResultLine({ label, result }: ServiceResultLineProps) {
  return (
    <p>
      {label}: {result.processed} processed, {result.skipped} skipped,{" "}
      {result.errors} errors
    </p>
  );
}
