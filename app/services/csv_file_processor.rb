class CsvFileProcessor
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :file
  attribute :filename, :string
  attribute :total_rows, :integer, default: 0
  attribute :processed_rows, :integer, default: 0
  attribute :encoding, :string
  attribute :debug_mode, :boolean, default: false

  validates :file, presence: true
  validate :file_must_be_valid

  MAX_FILE_SIZE = 10.megabytes
  COMMON_ENCODINGS = [
    'UTF-8',
    'Windows-1250',
    'ISO-8859-2',
    'Windows-1252',
    'ISO-8859-1',
    'CP852',
    'MacCentralEurope'
  ].freeze

  def process(&block)
    return [] unless valid?

    reset_counters
    rows = []
    detected_encoding = detect_encoding
    separator = detect_separator(detected_encoding)

    Rails.logger.info "Processing CSV with encoding: #{detected_encoding}, separator: #{separator.inspect}"
    begin
      csv_content = read_file_with_encoding(detected_encoding)
      if debug_mode
        Rails.logger.info "First 500 chars of CSV content:"
        Rails.logger.info csv_content[0..500].inspect
      end
      csv_options = {
        headers: true,
        col_sep: separator,
        liberal_parsing: true,
        skip_blanks: true,
        skip_lines: /^(?:,*|\s*)$/,
        quote_char: '"',
        row_sep: :auto
      }

      parsed_csv = CSV.parse(csv_content, **csv_options)
      if parsed_csv.headers
        Rails.logger.info "CSV Headers found: #{parsed_csv.headers.inspect}"
        Rails.logger.info "Header count: #{parsed_csv.headers.length}"
        cleaned_headers = parsed_csv.headers.map { |h| h&.strip&.downcase }
        Rails.logger.info "Cleaned headers: #{cleaned_headers.inspect}"
      else
        Rails.logger.warn "No headers found in CSV!"
      end
      parsed_csv.each_with_index do |row, index|
        self.total_rows += 1
        if debug_mode && index == 0
          Rails.logger.info "First row raw data:"
          row.headers.each do |header|
            Rails.logger.info "  #{header.inspect} => #{row[header].inspect}"
          end
        end

        next if row_blank?(row)

        processed_row = yield(row, total_rows) if block_given?

        if processed_row
          rows << processed_row
          self.processed_rows += 1
        end
      end

      log_summary
      rows
    rescue CSV::MalformedCSVError => e
      Rails.logger.error "CSV parsing error: #{e.message}"
      Rails.logger.error "Error occurred at line: #{e.line_number}" if e.respond_to?(:line_number)
      errors.add(:file, "CSV parsing error: #{e.message}")
      []
    rescue => e
      Rails.logger.error "Processing error: #{e.class} - #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      errors.add(:file, "Processing error: #{e.message}")
      []
    end
  end
  def self.find_column(row, *possible_names)
    return nil unless row

    possible_names.each do |name|
      value = row[name]
      return value.strip if value.present?
      row.headers.each do |header|
        next unless header
        if header.strip.downcase == name.downcase
          value = row[header]
          return value.strip if value.present?
        end
      end
    end

    nil
  end
  def inspect_csv
    detected_encoding = detect_encoding
    separator = detect_separator(detected_encoding)
    content = read_file_with_encoding(detected_encoding)

    puts "=" * 50
    puts "CSV File Analysis"
    puts "=" * 50
    puts "Encoding: #{detected_encoding}"
    puts "Separator: #{separator.inspect}"
    puts ""
    lines = content.lines.first(5)
    puts "First 5 lines (raw):"
    lines.each_with_index do |line, i|
      puts "Line #{i + 1}: #{line.inspect}"
    end
    puts ""
    begin
      csv = CSV.parse(content, headers: true, col_sep: separator, liberal_parsing: true)
      puts "Headers detected: #{csv.headers.inspect}"
      puts ""
      if csv.first
        puts "First data row:"
        csv.first.each do |header, value|
          puts "  #{header.inspect} => #{value.inspect}"
        end
      end
    rescue => e
      puts "Error parsing CSV: #{e.message}"
    end

    puts "=" * 50
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
      success_rate: success_rate,
      detected_encoding: encoding
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

  def read_file_with_encoding(encoding_name)
    content = File.read(file_path, mode: 'rb')
    content = remove_bom(content)
    content = content.gsub(/\r\n/, "\n")
    content = content.gsub(/\r/, "\n")
    if encoding_name == 'UTF-8'
      content.force_encoding('UTF-8')
      unless content.valid_encoding?
        content = content.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
      end
    else
      begin
        content.force_encoding(encoding_name)
        content = content.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
        Rails.logger.warn "Failed to convert from #{encoding_name}, trying Windows-1250: #{e.message}"
        content.force_encoding('Windows-1250')
        content = content.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
      end
    end

    content
  end

  def remove_bom(content)
    if content.start_with?("\xEF\xBB\xBF".force_encoding('ASCII-8BIT'))
      content = content[3..-1]
    elsif content.start_with?("\xFF\xFE".force_encoding('ASCII-8BIT'))
      content = content[2..-1]
    elsif content.start_with?("\xFE\xFF".force_encoding('ASCII-8BIT'))
      content = content[2..-1]
    end
    content
  end

  def detect_encoding
    return encoding if encoding.present?

    sample = File.read(file_path, 4096, mode: 'rb')
    if sample.start_with?("\xEF\xBB\xBF".force_encoding('ASCII-8BIT'))
      self.encoding = 'UTF-8'
      return 'UTF-8'
    elsif sample.start_with?("\xFF\xFE".force_encoding('ASCII-8BIT'))
      self.encoding = 'UTF-16LE'
      return 'UTF-16LE'
    elsif sample.start_with?("\xFE\xFF".force_encoding('ASCII-8BIT'))
      self.encoding = 'UTF-16BE'
      return 'UTF-16BE'
    end
    COMMON_ENCODINGS.each do |enc|
      begin
        test_sample = sample.dup
        test_sample.force_encoding(enc)
        test_sample.encode('UTF-8')

        larger_sample = File.read(file_path, [File.size(file_path), 10240].min, mode: 'rb')
        larger_sample.force_encoding(enc)
        larger_sample.encode('UTF-8')

        self.encoding = enc
        return enc
      rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
        next
      end
    end
    Rails.logger.warn "Could not detect encoding, defaulting to Windows-1250"
    self.encoding = 'Windows-1250'
    'Windows-1250'
  end

  def detect_separator(encoding_name = 'UTF-8')
    begin
      sample = File.read(file_path, 1024, mode: 'rb')
      sample = remove_bom(sample)
      sample.force_encoding(encoding_name)
      sample = sample.encode('UTF-8', invalid: :replace, undef: :replace) unless encoding_name == 'UTF-8'

      first_line = sample.split(/[\r\n]/).first || sample

      separators = {
        ',' => first_line.count(','),
        ';' => first_line.count(';'),
        "\t" => first_line.count("\t"),
        '|' => first_line.count('|')
      }

      separator = separators.max_by { |_sep, count| count }&.first || ','
      Rails.logger.debug "Detected separator: #{separator.inspect} (counts: #{separators})"
      separator
    rescue => e
      Rails.logger.warn "Error detecting separator: #{e.message}, defaulting to comma"
      ','
    end
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
    Rails.logger.info "CSV processed: #{total_rows} total rows, #{processed_rows} processed successfully (encoding: #{encoding})"
  end
end