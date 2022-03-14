module Macro
  def self.available
    # Should be automatic to provide an ordered list
    # Could use groups in the future
    [
      Macro::CreateCode,
      Macro::AssociateShape,
      Macro::UpdateStopAreaCompassBearing,
      Macro::CreateStopAreaReferents,
      Macro::AssociateStopAreaReferent,
      Macro::Dummy,
    ]
  end
end
