class PayloadStorageService
  CONTENT_TYPE = "application/json"
  KEY_EXTENSION = ".json"

  class StorageError < StandardError; end

  def initialize(client: S3_CLIENT, bucket: S3_BUCKET)
    @client = client
    @bucket = bucket
  end

  def store(key, payload)
    put_object(key, serialize(payload))
    key
  rescue Aws::S3::Errors::ServiceError => e
    raise_storage_error("store", e)
  end

  def retrieve(key)
    response = get_object(key)
    deserialize(response.body.read)
  rescue Aws::S3::Errors::NoSuchKey
    nil
  rescue Aws::S3::Errors::ServiceError => e
    raise_storage_error("retrieve", e)
  end

  def delete(key)
    delete_object(key)
    true
  rescue Aws::S3::Errors::ServiceError => e
    raise_storage_error("delete", e)
  end

  def exists?(key)
    head_object(key)
    true
  rescue Aws::S3::Errors::NotFound
    false
  rescue Aws::S3::Errors::ServiceError => e
    raise_storage_error("check existence of", e)
  end

  def generate_key(model_class, id)
    directory = model_class.name.underscore.pluralize
    "#{directory}/#{id}#{KEY_EXTENSION}"
  end

  private

  def put_object(key, body)
    @client.put_object(
      bucket: @bucket,
      key: key,
      body: body,
      content_type: CONTENT_TYPE
    )
  end

  def get_object(key)
    @client.get_object(bucket: @bucket, key: key)
  end

  def delete_object(key)
    @client.delete_object(bucket: @bucket, key: key)
  end

  def head_object(key)
    @client.head_object(bucket: @bucket, key: key)
  end

  def serialize(payload)
    payload.to_json
  end

  def deserialize(json_string)
    JSON.parse(json_string)
  end

  def raise_storage_error(operation, error)
    raise StorageError, "Failed to #{operation} payload: #{error.message}"
  end
end
