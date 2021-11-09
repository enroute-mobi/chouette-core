module Chouette
  class TimeTablePeriod < Chouette::ActiveRecord
    include ChecksumSupport
    acts_as_copy_target

    belongs_to :time_table, inverse_of: :periods

    scope :overlaps, -> (period_range) do
      where("(time_table_periods.period_start <= :end AND time_table_periods.period_end >= :begin)", {begin: period_range.begin, end: period_range.end})
    end

    validates_presence_of :period_start, :period_end
    validate :validate_period_uniqueness
    validate :start_must_be_before_end

    def validate_period_uniqueness
      overlapped_periods = time_table.periods.where.not(id: id).overlaps(range)
      puts "overlapped_periods #{overlapped_periods.inspect}" if overlapped_periods.present?
      errors.add(:overlapped_periods, I18n.t("time_tables.activerecord.errors.messages.overlapped_periods")) if overlapped_periods.present?
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

    def range
      period_start..period_end
    end

    def single_day?
      period_start == period_end
    end

    def self.transform_in_dates
      current_scope = self.current_scope || all

      single_day_periods = current_scope.where('period_start = period_end')

      single_day_periods.select(:period_start).find_each do |period|
        time_table.dates.create date: period.period_start, in_out: true
      end
      single_day_periods.delete_all
    end

  end
end
