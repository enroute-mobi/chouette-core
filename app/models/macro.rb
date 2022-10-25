module Macro
  def self.available
    # Should be automatic to provide an ordered list
    # Could use groups in the future
    [
      Macro::CreateCode,
      Macro::AssociateShape,
      Macro::CreateShape,
      Macro::UpdateStopAreaCompassBearing,
      Macro::CreateStopAreaReferents,
      Macro::AssociateStopAreaReferent,
      Macro::DefineAttributeFromParticulars,
      Macro::DefinePostalAddress,
      Macro::Dummy
    ]
  end
end
