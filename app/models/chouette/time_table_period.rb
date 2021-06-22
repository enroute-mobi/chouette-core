module Chouette
  class TimeTablePeriod < Chouette::ActiveRecord
    include ChecksumSupport
    acts_as_copy_target

    belongs_to :time_table, inverse_of: :periods

    validates_presence_of :period_start, :period_end

    validate :start_must_be_before_end

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
      if period_end <= period_start
        errors.add(:period_end,I18n.t("activerecord.errors.models.time_table_period.start_must_be_before_end"))
      end
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
