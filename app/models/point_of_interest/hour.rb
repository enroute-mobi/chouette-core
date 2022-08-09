# frozen_string_literal: true

module PointOfInterest
  class Hour < ApplicationModel
    self.table_name = 'point_of_interest_hours'

    belongs_to :point_of_interest, class_name: 'PointOfInterest::Base',
                                   inverse_of: :point_of_interest_hours

    validates :opening_time_of_day, presence: true
    validates :closing_time_of_day, presence: true
    validates :week_days, presence: true

    attribute :week_days, WeekDays.new

    def week_days_attributes=(attributes)
      self.week_days = Timetable::DaysOfWeek.new(attributes)
    end

    attribute :opening_time_of_day, TimeOfDay::Type::TimeWithoutZone.new
    attribute :closing_time_of_day, TimeOfDay::Type::TimeWithoutZone.new
  end
end
