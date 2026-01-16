class IngestionResult
  attr_reader :processed, :skipped, :errors

  def initialize
    @processed = 0
    @skipped = 0
    @errors = 0
  end

  def record_processed
    @processed += 1
  end

  def record_skipped
    @skipped += 1
  end

  def record_error
    @errors += 1
  end

  def to_h
    { processed: @processed, skipped: @skipped, errors: @errors }
  end

  def empty?
    total.zero?
  end

  def total
    @processed + @skipped + @errors
  end
end
