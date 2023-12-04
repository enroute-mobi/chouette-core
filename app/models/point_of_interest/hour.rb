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
      self.week_days = Cuckoo::Timetable::DaysOfWeek.new(attributes)
    end

    attribute :opening_time_of_day, TimeOfDay::Type::TimeWithoutZone.new
    attribute :closing_time_of_day, TimeOfDay::Type::TimeWithoutZone.new

    %i[opening_time_of_day closing_time_of_day].each do |attribute|
      # ?? Rails 5 ActiveRecord::AttributeAssignment .. doesn't create an object
      # by invoke writer with multiparameter attributes (like {1 => 13, 2 => 15})
      define_method "#{attribute}=" do |time_of_day|
        if time_of_day.is_a?(Hash) && time_of_day.keys == [1,2]
          time_of_day = TimeOfDay.new(time_of_day[1], time_of_day[2])
        end
        super time_of_day
      end
    end
  end
end
