class ReferentialOverview
  attr_reader :h
  attr_reader :referential

  PER_PAGE = 10

  def initialize referential, h=nil
    @referential = referential
    @page = h && h.params[pagination_param_name]&.to_i || 1
    @h = h
  end

  def lines
    filtered_lines.includes(:company).order(:name).map { |l| Line.new(l, @referential, period.first, h) }
  end

  def period
    @period ||= @referential.metadatas_period || []
  end

  def includes_today?
    period.include? Time.now.to_date
  end

  def weeks
    @weeks = {}
    period.map do |d|
      @weeks[Week.key(d)] ||= Week.new(d, period.last, h)
    end
    @weeks.values
  end

  def referential_lines
    @referential.metadatas_lines
  end

  def filtered_lines
    search.result.page(@page).per_page(PER_PAGE)
  end

  ### Pagination

  delegate :empty?, :first, :total_pages, :size, :total_entries, :offset, :length, to: :filtered_lines
  def current_page
    @page
  end

  ### search
  def search
    lines = referential_lines
    lines = lines.ransack h.params[search_param_name]
    lines
  end

  def pagination_param_name
    "referential_#{@referential.slug}_overview"
  end

  def search_param_name
    "q_#{pagination_param_name}"
  end

  class Line
    attr_reader :h
    attr_reader :referential_line

    delegate :name, :number, :company, :color, :text_color, :transport_mode, to: :referential_line

    def initialize line, referential, start, h
      @referential_line = line
      @referential = referential
      @start = start
      @h = h
    end

    def period
      @period ||= @referential.metadatas_period || []
    end

    def referential_periods
      @referential_periods ||= @referential.metadatas.include_lines([@referential_line.id]).map(&:periodes).flatten.sort{|p1, p2| p1.first <=> p2.first}
    end

    def holes
      @holes ||= []
      # @holes ||= begin
      #   holes = ServiceCount.holes_for_line(@referential_line).map { |hole| Period.new (hole.date..hole.date), @start, h }
      #   holes = merge_periods holes, join: true
      # end
    end

    def periods
      @periods ||= begin
        periods = referential_periods.flatten.map { |p| Period.new p, @start, h }
        periods = fill_periods periods
        periods = merge_periods periods
        periods
      end
    end

    def fill_periods(periods)
      [].tap do |out|
        previous = OpenStruct.new(end: period.first - 1.day)
        (periods + [OpenStruct.new(start: period.last + 1.day)]).each do |p|
          if p.start > previous.end + 1.day
            out << Period.new((previous.end+1.day..p.start - 1.day), @start, h).tap { |pp| pp.empty = true }
          end
          out << p if p.respond_to?(:end)
          previous = p
        end
      end
    end

    def merge_periods(periods, join: false)
      return periods unless periods.size > 1

      [].tap do |out|
        current = periods.first
        periods[1..-1].each do |p|
          test = p.start <= current.end
          test = test || join && p.start == current.end + 1
          if test
            current.end = p.end
          else
            out << current
            current = p
          end
        end
        out << current
      end
    end

    def width
      period.count * Day::WIDTH
    end

    def html_style
      {
        width: "#{width}px"
      }.map{|k, v| "#{k}: #{v}"}.join('; ')
    end

    def html_class
      out = []
      out
    end

    class Period
      attr_accessor :empty
      attr_accessor :h

      def initialize(period, start, h, opts={})
        @period = period
        @start = start
        @empty = false
        @h = h
        @hole = opts[:hole]
      end

      def start
        @period.first
      end

      def end
        @period.last
      end

      def end=(val)
        @period = (start..val)
      end

      def size
        @period.count
      end

      def width
        size * Day::WIDTH
      end

      def left
        (@period.first - @start).to_i * Day::WIDTH
      end

      def html_style
        {
          width: "#{width}px",
          left: "#{left}px",
        }.map{|k, v| "#{k}: #{v}"}.join('; ')
      end

      def empty?
        @empty
      end

      # Display title if we have at least 2 days
      def title
        h.l(self.start) + ' - ' + h.l(self.end) if size > 1
      end

      def html_class
        out = []
        out << "empty" if empty?
        out
      end
    end
  end

  class Week
    attr_reader :h
    attr_reader :start_date
    attr_reader :end_date

    def initialize start_date, boundary, h
      @start_date = start_date.to_date
      @end_date = [start_date.end_of_week, boundary].min.to_date
      @h = h
    end

    def self.key date
      date.beginning_of_week.to_s
    end

    def span
      if @start_date.month == @end_date.month
        h.l(@start_date, format: "#{@start_date.day}-#{@end_date.day} %b %Y")
      else
        "#{h.l(@start_date, format: "%d %b")} - #{h.l(@end_date, format: "%d %b %Y")}"
      end
    end

    def number
      h.l(@start_date, format: "%W")
    end

    def period
      (@start_date..@end_date)
    end

    def days
      period.map {|d| Day.new d, h }
    end
  end

  class Day
    attr_reader :h

    WIDTH=50

    def initialize date, h
      @date = date
      @h = h
    end

    def html_style
      {width: "#{WIDTH}px"}.map{|k, v| "#{k}: #{v}"}.join("; ")
    end

    def html_class
      out = [h.l(@date, format: "%Y-%m-%d")]
      out << "weekend" if [0, 6].include?(@date.wday)
      out << "today" if @date == Time.now.to_date
      out
    end

    def short_name
      h.l(@date, format: "%a")
    end

    def number
      @date.day
    end
  end
end
