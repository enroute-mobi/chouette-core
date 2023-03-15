module StopAreaReferentialSupport
  extend ActiveSupport::Concern

  included do
    belongs_to :stop_area_referential
    belongs_to :stop_area_provider, required: true

    validates_presence_of :stop_area_referential
    alias_method :referential, :stop_area_referential

    # Must be defined before ObjectidSupport
    before_validation :define_stop_area_referential, on: :create
  end

  def workgroup
    @workgroup ||= CustomFieldsSupport.current_workgroup ||
                   Workgroup.where(stop_area_referential_id: stop_area_referential_id).last
  end

  private

  def define_stop_area_referential
    # TODO Improve performance ?
    self.stop_area_referential ||= stop_area_provider&.stop_area_referential
  end
end
