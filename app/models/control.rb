# frozen_string_literal: true

module Control
  def self.available # rubocop:disable Metrics/MethodLength
    # Should be automatic to provide an *ordered* list
    # Could use groups in the future
    [
      Control::Dummy,
      Control::PresenceAttribute,
      Control::PresenceCode,
      Control::PresenceCustomField,
      Control::CodeFormat,
      Control::FormatAttribute,
      Control::ModelStatus,
      Control::JourneyPatternSpeed,
      Control::ServiceCountTrend,
      Control::PresenceAssociatedModel,
      Control::PassingTimesInTimeRange,
      Control::GeographicalZone,
      Control::ExpectedProvider
    ]
  end
end
