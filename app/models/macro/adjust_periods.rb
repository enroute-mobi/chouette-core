# frozen_string_literal: true

module Macro
  class AdjustPeriods < Macro::Base
    module Options
      extend ActiveSupport::Concern

      included do
        option :end_correction

        validates :end_correction, numericality: { only_integer: true, other_than: 0 }
      end
    end

    include Options

    class Run < Macro::Base::Run
      include Options

      def run
        time_table_periods.includes(:time_table).find_each do |period|
          period.update period_end: (period.period_end + end_correction)
          create_message period
        end
      end

      delegate :time_table_periods, to: :scope

      def create_message(period)
        attributes = {
          message_attributes: {
            name: period.time_table.name,
            period_end: I18n.l(period.period_end)
          },
          source: period.time_table
        }

        attributes.merge!(criticity: 'error', message_key: 'error') unless period.valid?

        macro_messages.create!(attributes)
      end
    end
  end
end
