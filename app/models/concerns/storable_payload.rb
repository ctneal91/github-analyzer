module StorablePayload
  extend ActiveSupport::Concern

  STORAGE_ENABLED_ENV_VAR = "PAYLOAD_STORAGE_ENABLED"
  STORAGE_ENABLED_VALUE = "true"
  LOG_TAG = "[StorablePayload]"

  included do
    after_create :persist_payload_to_storage, if: :should_persist_to_storage?
    after_destroy :remove_payload_from_storage, if: :has_stored_payload?
  end

  def raw_payload
    return cached_payload if payload_cached?
    return database_payload unless has_stored_payload?

    cache_payload(fetch_from_storage || database_payload)
  end

  def raw_payload=(value)
    cache_payload(value)
    write_attribute(:raw_payload, value)
  end

  private

  # Caching

  def payload_cached?
    defined?(@raw_payload)
  end

  def cached_payload
    @raw_payload
  end

  def cache_payload(value)
    @raw_payload = value
  end

  def database_payload
    read_attribute(:raw_payload)
  end

  # Storage conditions

  def should_persist_to_storage?
    storage_enabled? && raw_payload.present?
  end

  def has_stored_payload?
    payload_key.present?
  end

  def storage_enabled?
    ENV[STORAGE_ENABLED_ENV_VAR] == STORAGE_ENABLED_VALUE
  end

  # Storage operations

  def persist_payload_to_storage
    key = generate_storage_key
    storage_service.store(key, raw_payload)
    save_storage_key(key)
  rescue PayloadStorageService::StorageError => e
    log_storage_error("store", e)
  end

  def fetch_from_storage
    storage_service.retrieve(payload_key)
  rescue PayloadStorageService::StorageError => e
    log_storage_error("fetch", e)
    nil
  end

  def remove_payload_from_storage
    storage_service.delete(payload_key)
  rescue PayloadStorageService::StorageError => e
    log_storage_error("delete", e)
  end

  # Helpers

  def generate_storage_key
    storage_service.generate_key(self.class, id)
  end

  def save_storage_key(key)
    update_column(:payload_key, key)
  end

  def storage_service
    @storage_service ||= PayloadStorageService.new
  end

  def log_storage_error(operation, error)
    Rails.logger.error("#{LOG_TAG} Failed to #{operation} payload: #{error.message}")
  end
end
