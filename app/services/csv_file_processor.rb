class CsvFileProcessor
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :file
  attribute :filename, :string
  attribute :total_rows, :integer, default: 0
  attribute :processed_rows, :integer, default: 0

  validates :file, presence: true
  validate :file_must_be_valid

  MAX_FILE_SIZE = 10.megabytes

  def process(&block)
    return [] unless valid?

    reset_counters
    rows = []

    CSV.foreach(file_path, headers: true) do |row|
      self.total_rows += 1
      next if row_blank?(row)

      processed_row = yield(row, total_rows) if block_given?
      
      if processed_row
        rows << processed_row
        self.processed_rows += 1
      end
    end

    log_summary
    rows
  end

  def success_rate
    return 0 if total_rows.zero?
    (processed_rows.to_f / total_rows * 100).round(1)
  end

  def summary
    {
      filename: filename,
      total_rows: total_rows,
      processed_rows: processed_rows,
      success_rate: success_rate
    }
  end

  private

  def file_path
    @file_path ||= file.respond_to?(:path) ? file.path : file
  end

  def reset_counters
    self.total_rows = 0
    self.processed_rows = 0
  end

  def row_blank?(row)
    row.to_h.values.all?(&:blank?)
  end

  def file_must_be_valid
    return unless file

    self.filename = file.respond_to?(:original_filename) ? 
                   file.original_filename : File.basename(file)

    errors.add(:file, "not found") unless File.exist?(file_path)
    errors.add(:file, "is empty") if File.zero?(file_path)
    errors.add(:file, "too large (max #{MAX_FILE_SIZE / 1.megabyte}MB)") if File.size(file_path) > MAX_FILE_SIZE
  end

  def log_summary
    Rails.logger.info "CSV processed: #{total_rows} total rows, #{processed_rows} processed successfully"
  end
end 