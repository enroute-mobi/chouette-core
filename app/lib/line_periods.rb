class LinePeriods

  def initialize
    @periods_by_line = Hash.new { |h,k| h[k] = [] }
  end

  def add(line_id, period)
    @periods_by_line[line_id] << period
  end

  def each(&block)
    @periods_by_line.each do |line_id, periods|
      yield line_id, periods
    end
  end

  def initialize_copy(orig)
    super
    @periods_by_line = orig.periods_by_line.deep_dup
  end

  def merge(other)
    dup.merge! other
  end

  # Keep periods unchanged
  def merge!(other)
    other.each do |line_id, periods|
      periods.each do |period|
        add line_id, period
      end
    end
    self
  end

  def periods(line_id)
    @periods_by_line[line_id]
  end

  def to_s
    @periods_by_line.inspect
  end

  def ==(other)
    periods_by_line == other.periods_by_line
  end

  def self.from_metadatas(metadatas)
    line_periods = new

    metadatas.each do |metadata|
      metadata.line_ids.each do |line_id|
        metadata.periodes.each do |period|
          line_periods.add(line_id, period)
        end
      end
    end

    line_periods
  end

  protected

  attr_reader :periods_by_line

end
