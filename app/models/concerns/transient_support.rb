# Transient information associated to the Model but not saved
#
# Used, for example, during import to associated identifier
#
#   stop_point = Chouette::StopPoint.new(...).with_transient(stop_id: gtfs_stop_id)
#   stop_point.transient(:stop_id)
#
module TransientSupport
  extend ActiveSupport::Concern

  def transient(name)
    transients[name]
  end

  def with_transient(attributes = {})
    transients.merge! attributes
    self
  end

  private

  def transients
    @transients ||= {}
  end
end
