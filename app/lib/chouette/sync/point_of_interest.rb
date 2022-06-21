module Chouette::Sync
  module PointOfInterest
    class Netex < Chouette::Sync::Base

      def initialize(options = {})
        default_options = {
          resource_type: :point_of_interest,
          resource_id_attribute: :id,
          model_type: :point_of_interest,
          resource_decorator: Decorator,
          model_id_attribute: :codes,
        }
        options.reverse_merge!(default_options)
        super options
      end

      class Decorator < Chouette::Sync::Updater::ResourceDecorator

        delegate :contact_details, to: :operating_organisation_view
        delegate :target, to: :updater

        def position
          "#{longitude} #{latitude}"
        end

        def address
          postal_address&.address_line_1
        end

        def zip_code
          postal_address&.post_code
        end

        def city_name
          postal_address&.town
        end

        def country
          postal_address&.country_name
        end

        def email
          contact_details&.email
        end

        def phone
          contact_details&.phone
        end

        def point_of_interest_category_name
          classifications.first&.name
        end

        def point_of_interest_category
          if point_of_interest_category_name.present?
            point_of_interest_categories.find_by(name: point_of_interest_category_name)
          end
        end

        def point_of_interest_category_id
          point_of_interest_category&.id
        end

        def point_of_interest_categories
          target.point_of_interest_categories
        end

        def codes_attributes
          return [] unless key_list.present?
          key_list.map do |netex_code|
            {
              short_name: netex_code.key,
              value: netex_code.value
            }
          end
        end

        class Hour
          def initialize(point_of_interest)
            @point_of_interest = point_of_interest
          end
          attr_accessor :point_of_interest

          delegate :validity_conditions, to: :point_of_interest

          def hours_attributes
            [].tap do |point_of_interest_hours_attributes|
              validity_conditions.each do |validity_condition|
                if (timebands = validity_condition.timebands.presence) &&
                  (day_types = validity_condition.day_types.presence)
                  timebands.each do |timeband|
                    day_types.each do |day_type|
                      if properties = day_type.properties.presence
                        properties.each do |property|
                          point_of_interest_hours_attributes << {
                            opening_time_of_day: netex_time_of_day(timeband.start_time),
                            closing_time_of_day: netex_time_of_day(timeband.end_time),
                            week_days: netex_week_days(property.days_of_week)
                          }
                        end
                      end
                    end
                  end
                end
              end
            end
          end

          private

          def netex_time_of_day(time)
            TimeOfDay.new time.hour, time.minute, time.second
          end

          def netex_week_days(days_of_week)
            Timetable::DaysOfWeek.new.tap do |dow|
              days_of_week.split(/\s/).map(&:to_sym).each do |day|
                dow.send("#{day.downcase}=", true)
              end
            end
          end
        end

        def hours_attributes
          Hour.new(self).hours_attributes
        end

        def model_attributes
          {
            name: name,
            url: url,
            position_input: position,
            address: address,
            zip_code: zip_code,
            city_name: city_name,
            country: country,
            phone: phone,
            email: email,
            point_of_interest_category_id: point_of_interest_category_id,
            point_of_interest_hours_attributes: hours_attributes,
            codes_attributes: codes_attributes
          }
        end
      end
    end
  end
end
