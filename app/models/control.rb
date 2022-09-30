module Control
  def self.available
    # Should be automatic to provide an ordered list
    # Could use groups in the future
    [
      Control::Dummy,
      Control::PresenceAttribute,
      Control::PresenceCode,
      Control::PresenceCustomField,
      Control::CodeFormat,
      Control::FormatAttribute,
      Control::ModelStatus,
      Control::ServiceCountTrend,
    ]
  end
end
