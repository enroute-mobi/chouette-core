# frozen_string_literal: true

module Chouette
  module Sync
    module BookingArrangement
      class Netex < Chouette::Sync::Base
        def initialize(options = {})
          default_options = {
            resource_type: :booking_arrangement,
            resource_id_attribute: :id,
            model_type: :booking_arrangement,
            resource_decorator: Decorator,
            model_id_attribute: :codes
          }
          options.reverse_merge!(default_options)
          super options
        end

        class Decorator < Chouette::Sync::Netex::Decorator
          delegate :phone, :url, to: :booking_contact, allow_nil: true

          def model_attributes
            {
              name: "Netex Booking Arrangement #{id}",
              phone: phone,
              url: url,
              booking_methods: netex_booking_methods,
              booking_access: netex_booking_access,
              book_when: netex_book_when,
              latest_booking_time: netex_latest_booking_time,
              buy_when: netex_buy_when,
              minimum_booking_period: netex_minimum_booking_period,
              booking_url: booking_url,
              booking_notes: booking_note
            }
          end

          def netex_booking_methods
            [booking_methods.underscore]
          end

          def netex_booking_access
            booking_access.underscore
          end

          def netex_book_when
            book_when.underscore
          end

          def netex_buy_when
            buy_when.underscore
          end

          def netex_minimum_booking_period
            minimum_booking_period.scan(/\d+/).first&.to_i
          end

          def netex_latest_booking_time
            TimeOfDay.new(
              latest_booking_time.hour,
              latest_booking_time.minute,
              latest_booking_time.second
            )
          end
        end
      end
    end
  end
end
