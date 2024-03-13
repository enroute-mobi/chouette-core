# frozen_string_literal: true

module VehicleJourneysHelper
  def display_time_of_day(time_of_day)
    return '-' unless time_of_day

    if time_of_day.day_offset?
      I18n.t('vehicle_journeys.index.vjas.time_of_day', time: time_of_day.to_hms, offset: time_of_day.day_offset)
    else
      time_of_day.to_hms
    end
  end
end
