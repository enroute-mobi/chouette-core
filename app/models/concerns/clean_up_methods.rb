module CleanUpMethods
  # EXTRA CLEANINGS, SELECTED FROM THE UI

  def clean_vehicle_journeys_without_time_table
    Chouette::Benchmark.measure 'clean_vehicle_journeys_without_time_table' do
      Chouette::VehicleJourney.without_any_time_table.clean!
    end
  end

  def clean_journey_patterns_without_vehicle_journey
    Chouette::Benchmark.measure 'clean_journey_patterns_without_vehicle_journey' do
      Chouette::JourneyPattern.without_any_vehicle_journey.clean!
    end
  end

  def clean_routes_without_journey_pattern
    Chouette::Benchmark.measure 'clean_routes_without_journey_pattern' do
      Chouette::Route.without_any_journey_pattern.clean!
    end
  end

  def clean_unassociated_timetables
    Chouette::Benchmark.measure 'clean_unassociated_timetables' do
      Chouette::TimeTable.not_associated.clean!
    end
  end

  def clean_unassociated_purchase_windows
    Chouette::Benchmark.measure 'clean_unassociated_purchase_windows' do
      Chouette::PurchaseWindow.not_associated.clean!
    end
  end

  # DEFAULT CLEANINGS

  def clean_timetables_and_children
    Chouette::Benchmark.measure('clean_timetables_and_children') do
      ActiveRecord::Base.cache do
        return unless date_type.present?

        Chouette::Benchmark.measure('clean_time_tables'){ clean_time_tables }
        Chouette::Benchmark.measure('clean_time_table_dates'){ clean_time_table_dates }
        Chouette::Benchmark.measure('clean_time_table_periods'){ clean_time_table_periods }

        Chouette::Benchmark.measure('update_shortcuts') do
          Chouette::TimeTable.includes(:dates, :periods).find_each &:save_shortcuts
        end
      end
    end
  end

  def clean_time_tables
    time_tables = case date_type.to_sym
    when :before
      Chouette::TimeTable.where('end_date < ?', self.begin_date)
    when :after
      Chouette::TimeTable.where('start_date > ?', self.begin_date)
    when :outside
      Chouette::TimeTable.where('start_date > ? OR end_date < ?', self.end_date, self.begin_date)
    when :between
      Chouette::TimeTable.where('start_date > ? AND end_date < ?', self.begin_date, self.end_date)
    end

    time_tables.clean!
  end

  def clean_time_table_dates
    dates = Chouette::TimeTableDate.in_dates
    dates = case date_type.to_sym
    when :before
      dates.where('date < ?', self.begin_date)
    when :after
      dates.where('date > ?', self.begin_date)
    when :outside
      dates.where('date < ? OR date > ?', self.begin_date, self.end_date)
    when :between
      dates.where('date > ? AND date < ?', self.begin_date, self.end_date)
    end

    dates.clean!
  end

  def clean_time_table_periods
    periods = Chouette::TimeTablePeriod
    periods = case date_type.to_sym
    when :before
      periods.where('period_end < ?', self.begin_date)
    when :after
      periods.where('period_start > ?', self.begin_date)
    when :outside
      periods.where('period_end < ? OR period_start > ?', self.begin_date, self.end_date)
    when :between
      periods.where('period_start >= ? AND period_end <= ?', self.begin_date, self.end_date)
    end

    periods.clean!
    truncate_time_table_periods
  end

  def truncate_time_table_periods
    periods = Chouette::TimeTablePeriod

    truncated_periods = []
    case date_type.to_sym
    when :before
      periods.where('period_start < ? AND period_end >= ?', self.begin_date, self.begin_date).find_each do |period|
        period.period_start = self.begin_date
        truncated_periods << period
      end
    when :after
      periods.where('period_start <= ? AND period_end > ?', self.begin_date, self.begin_date).find_each do |period|
        period.period_end = self.begin_date
        truncated_periods << period
      end
    when :outside
      periods.where('period_start < ? AND period_end >= ?', self.begin_date, self.begin_date).find_each do |period|
        period.period_start = self.begin_date
        truncated_periods << period
      end
      periods.where('period_start <= ? AND period_end > ?', self.end_date, self.end_date).find_each do |period|
        period.period_end = self.end_date
        truncated_periods << period
      end
    when :between
      periods.where('period_start < ? AND period_end > ?', self.begin_date, self.end_date).find_each do |period|
        truncated_periods << period.time_table.periods.build(period_start: period.period_start, period_end: self.begin_date - 1)
        truncated_periods << period.time_table.periods.build(period_start: self.end_date + 1, period_end: period.period_end)
        period.delete
      end
      periods.where('period_start < ? AND period_end >= ?', self.begin_date, self.begin_date).find_each do |period|
        period.period_end = self.begin_date - 1
        truncated_periods << period
      end
      periods.where('period_start <= ? AND period_end > ?', self.end_date, self.end_date).find_each do |period|
        period.period_start = self.end_date + 1
        truncated_periods << period
      end
    end

    truncated_periods.each do |period|
      if period.single_day?
        period.time_table.dates.create(date: period.period_start, in_out: true)
        period.delete if period.persisted?
      else
        period.save!
      end
    end
  end

  def clean_routes_outside_referential
    Chouette::Benchmark.measure 'clean_routes_outside_referential' do
      line_ids = referential.metadatas.pluck(:line_ids).flatten.uniq
      Chouette::Route.where(['line_id not in (?)', line_ids]).clean!
    end
  end

  # CLEANUPS THAT CAN BE TRIGGERED PROGRAMATICALLY

  def clean_unassociated_vehicle_journeys
    Chouette::Benchmark.measure 'clean_unassociated_vehicle_journeys' do
      Chouette::VehicleJourney.where("id not in (select distinct vehicle_journey_id from time_tables_vehicle_journeys)").clean!
    end
  end

  def clean_unassociated_journey_patterns
    Chouette::Benchmark.measure 'clean_unassociated_journey_patterns' do
      Chouette::JourneyPattern.where("id not in (select distinct journey_pattern_id from vehicle_journeys)").clean!
    end
  end

  def clean_unassociated_routes
    Chouette::Benchmark.measure 'clean_unassociated_routes' do
      Chouette::Route.where("id not in (select distinct route_id from journey_patterns)").clean!
    end
  end

  def clean_unassociated_footnotes
    Chouette::Footnote.not_associated.clean!
  end

  def clean_unassociated_calendars
    clean_unassociated_timetables
    clean_unassociated_purchase_windows
  end

  def clean_irrelevant_data
    clean_unassociated_vehicle_journeys
    clean_unassociated_journey_patterns
    clean_unassociated_routes
    clean_unassociated_footnotes
  end
end
