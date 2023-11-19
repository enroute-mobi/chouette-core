class ZipService

  class Subdir < Struct.new(:name, :stream, :spurious, :foreign_lines, :missing_calendar, :wrong_calendar)
    def ok?
      foreign_lines.empty? && spurious.empty? && !missing_calendar && !wrong_calendar
    end
  end

  class TooManyDirectoriesError < StandardError; end

  attr_reader :allowed_lines, :current_key, :foreign_lines, :current_output, :current_spurious, :yielder

  def initialize data, allowed_lines
    @zip_data       = StringIO.new(data)
    @allowed_lines  = allowed_lines
    @current_key    = nil
    @current_output = nil
  end

  def subdirs
    Enumerator.new do |yielder|
      @yielder = yielder
      Zip::File.open_buffer(@zip_data, &(method :_subdirs))
    end
  end

  def _subdirs zip_file
    zip_file.each do | entry |
      add_entry entry
    end
    finish_current_output
  end

  def add_entry entry
    key = entry_key entry
    unless key == current_key
      raise TooManyDirectoriesError  unless current_key.nil?
      finish_current_output
      open_new_output key
    end
    add_to_current_output entry
  end

  def validate entry
    if is_calendar_file?(entry.name)
      @current_calendar_is_missing = false
      if wrong_calendar_data?(entry)
        @current_calendar_is_wrong = true
        return false
      end
    end
    return false if is_spurious?(entry.name)
    return false if is_foreign_line?(entry.name)
    true
  end

  def add_to_current_output entry
    return unless validate(entry)

    current_output.put_next_entry entry.name
    write_to_current_output entry.get_input_stream
  end

  def write_to_current_output input_stream
    # the condition below is true for directory entries
    return if Zip::NullInputStream == input_stream
    current_output.write input_stream.read
  end

  def finish_current_output
    if current_output
      @yielder  << Subdir.new(
        current_key,
        # Second part of the solution, yield the closed stream
        current_output.close_buffer,
        current_spurious.to_a,
        foreign_lines,
        @current_calendar_is_missing,
        @current_calendar_is_wrong)
    end
  end

  def open_new_output entry_key
    @current_key    = entry_key
    # First piece of the solution, use internal way to create a Zip::OutputStream
    @current_output   = Zip::OutputStream.new(StringIO.new(''), true, nil)
    @current_spurious = Set.new
    @foreign_lines    = []
    @current_calendar_is_missing = true
    @current_calendar_is_wrong = false
  end

  def entry_key entry
    # last dir name File.dirname.split("/").last
    entry.name.split('/').first
  end

  def is_spurious? entry_name
    segments = entry_name.split('/', 3)
    return false if segments.size < 3

    current_spurious << segments.second
    return true
  end

  def is_foreign_line? entry_name
    STIF::NetexFile::Frame.get_short_id(entry_name).tap do | line_object_id |
      return nil unless line_object_id
      return nil if line_object_id.in? allowed_lines
      foreign_lines << line_object_id
    end
  end

  def is_calendar_file? entry_name
    entry_name =~ /calendriers.xml$/
  end

  def wrong_calendar_data? entry
    content = entry.get_input_stream.read
    periods = STIF::NetexFile::Frame.parse_calendars content.to_s
    periods.each do |period|

      return true unless period
      return true unless period.first
      return true unless period.end
      return true unless period.first <= period.end
    end
    false
  rescue
    true
  end
end
