module Chouette::Sync
  module PointOfInterest
    class Netex < Chouette::Sync::Base
      def initialize(options = {})
        default_options = {
          resource_type: :point_of_interest,
          resource_id_attribute: :id,
          model_type: :point_of_interest,
          resource_decorator: Decorator,
          model_id_attribute: :codes
        }
        options.reverse_merge!(default_options)
        super options
      end

      class Decorator < Chouette::Sync::Updater::ResourceDecorator
        delegate :contact_details, to: :operating_organisation_view, allow_nil: true
        delegate :target, to: :updater

        def position
          "#{longitude} #{latitude}"
        end

        delegate :postal_region, :address_line_1, to: :postal_address, allow_nil: true

        def zip_code
          postal_address&.post_code
        end

        def city_name
          postal_address&.town
        end

        def country
          postal_address&.country_name
        end

        delegate :email, :phone, to: :contact_details, allow_nil: true

        def point_of_interest_category_name
          classifications.first&.name
        end

        def point_of_interest_category
          return unless point_of_interest_category_name.present?

          point_of_interest_categories.find_by(name: point_of_interest_category_name)
        end

        def point_of_interest_category_id
          point_of_interest_category&.id
        end

        def point_of_interest_categories
          target.point_of_interest_categories
        end

        class Hour
          def initialize(validity_conditions)
            @validity_conditions = validity_conditions
          end
          attr_accessor :validity_conditions

          def hours_attributes
            [].tap do |hours_attributes|
              validity_conditions.each do |validity_condition|
                validity_condition.timebands.each do |timeband|
                  # All DayTypes are merged into a single DaysOfWeek
                  days_of_week = netex_week_days(validity_condition.day_types)

                  hours_attributes << {
                    opening_time_of_day: netex_time_of_day(timeband.start_time),
                    closing_time_of_day: netex_time_of_day(timeband.end_time),
                    week_days: days_of_week
                  }
                end
              end
            end
          end

          private

          def netex_time_of_day(time)
            TimeOfDay.new time.hour, time.minute, time.second
          end

          def netex_week_days(day_types)
            Cuckoo::Timetable::DaysOfWeek.new.tap do |dow|
              day_types.each do |day_type|
                day_type.properties.each do |property|
                  property.days_of_week.split(/\s/).map(&:downcase).each do |day|
                    dow.send("#{day}=", true)
                  end
                end
              end
            end
          end
        end

        def hours_attributes
          Hour.new(validity_conditions).hours_attributes
        end

        def model_attributes # rubocop:disable Metrics/MethodLength
          {
            name: name,
            url: url,
            position_input: position,
            address_line_1: address_line_1,
            zip_code: zip_code,
            city_name: city_name,
            postal_region: postal_region,
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
