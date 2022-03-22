module Control
  def self.available
    # Should be automatic to provide an ordered list
    # Could use groups in the future
    [
      Control::Dummy,
      Control::PresenceAttribute
    ]
  end
end
