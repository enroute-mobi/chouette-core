module StopAreaReferentialSupport
  extend ActiveSupport::Concern

  included do
    belongs_to :stop_area_referential
    validates_presence_of :stop_area_referential
    alias_method :referential, :stop_area_referential
  end

  def workgroup
    @workgroup ||= self.class.current_workgroup || Workgroup.where(stop_area_referential_id: stop_area_referential_id).last
  end

  def hub_restricted?
    false
  end
end
