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
          messages.create(source: period.time_table, period_end: I18n.l(period.period_end)) do |message|
            message.error! unless period.valid?
          end
        end
      end

      delegate :time_table_periods, to: :scope
    end
  end
end
