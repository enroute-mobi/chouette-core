module Macro
  def self.available # rubocop:disable Metrics/MethodLength
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
      Macro::ComputeJourneyPatternDurations,
      Macro::ComputeJourneyPatternDistances,
      Macro::AssociateShapeAccordingWaypoints,
      Macro::UpdateAttributeFromReferentToParticulars,
      Macro::DeleteVehicleJourneys,
      Macro::ComputeServiceCounts,
      Macro::AssociateDocuments,
      Macro::Dummy # Keep this dummy last
    ]
  end
end
