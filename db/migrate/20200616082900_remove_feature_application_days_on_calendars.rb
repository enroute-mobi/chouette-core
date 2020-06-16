class RemoveFeatureApplicationDaysOnCalendars < ActiveRecord::Migration[5.2]
  def up
    on_public_schema_only do
      Organisation.all.each do |org|
        org.update(features: org.features-['application_days_on_calendars'])
      end
    end
  end
end
