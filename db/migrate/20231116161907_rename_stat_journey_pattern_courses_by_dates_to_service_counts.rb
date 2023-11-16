class RenameStatJourneyPatternCoursesByDatesToServiceCounts < ActiveRecord::Migration[5.2]
  def change
    rename_table :stat_journey_pattern_courses_by_dates, :service_counts
  end
end
