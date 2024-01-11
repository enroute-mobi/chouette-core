module Chouette
  class TimeTablePeriod < Chouette::ActiveRecord
    include ChecksumSupport
    acts_as_copy_target

    belongs_to :time_table, inverse_of: :periods

    scope :overlaps, -> (period_range) do
      where("(time_table_periods.period_start <= :end AND time_table_periods.period_end >= :begin)", {begin: period_range.begin, end: period_range.end})
    end

    scope :overlapping_siblings, -> {
      joins("inner join time_table_periods as brother on time_table_periods.time_table_id = brother.time_table_id and time_table_periods.id <> brother.id").where("time_table_periods.period_start <= brother.period_end AND time_table_periods.period_end >= brother.period_start")
    }

    validates :period_start, :period_end, presence: true
    validate :start_must_be_before_end

    with_options(if: -> { validation_context != :inserter }) do |except_in_inserter_context|
      except_in_inserter_context.validate :validate_period_uniqueness
    end

    def validate_period_uniqueness
      return unless time_table
      # We should never read database (with where for example) otherwise memory validation fails
      intersection = time_table.periods.any? do |other|
        other != self && other.overlap?(self)
      end

      if intersection
        Rails.logger.error "TimeTablePeriod from #{period_start} to #{period_end} can't be saved for TimeTable #{time_table.id}"
        errors.add(:overlapped_periods, I18n.t("activerecord.time_table.errors.messages.overlapped_periods"))
      end
    end

    def checksum_attributes(db_lookup = true)
      attrs = ['period_start', 'period_end']
      self.slice(*attrs).values
    end

    def self.model_name
      ActiveModel::Name.new Chouette::TimeTablePeriod, Chouette, "TimeTablePeriod"
    end

    def start_must_be_before_end
      # security against nil values
      if period_end.nil? || period_start.nil?
        return
      end

      errors.add(:period_end,I18n.t("activerecord.errors.models.time_table_period.start_must_be_before_end")) if period_end <= period_start
    end

    def copy
      Chouette::TimeTablePeriod.new(:period_start => self.period_start,:period_end => self.period_end)
    end

    # Test to see if a period overlap this period
    def overlap?(p)
      (p.period_start >= self.period_start && p.period_start <= self.period_end) || (p.period_end >= self.period_start && p.period_end <= self.period_end)
    end

    # Test to see if a period is included in this period
    def contains?(p)
      (p.period_start >= self.period_start && p.period_end <= self.period_end)
    end

    def intersect?(other)
      (range & other).present?
    end

    def include?(date)
      range.include? date
    end

    def range
      period_start..period_end
    end

    def range=(range)
      self.period_start = range.min
      self.period_end = range.max
    end

    def single_day?
      period_start == period_end
    end

    def self.transform_in_dates
      current_scope = self.current_scope || all

      single_day_periods = current_scope.where('period_start = period_end')

      single_day_periods.select(:id, :time_table_id, :period_start).find_each do |period|
        period.time_table.dates.create date: period.period_start, in_out: true
      end
      single_day_periods.delete_all
    end

  end
end
