# frozen_string_literal: true

module StopAreaReferentialSupport
  extend ActiveSupport::Concern

  included do
    belongs_to :stop_area_referential # CHOUETTE-3247 required: true
    belongs_to :stop_area_provider # CHOUETTE-3247 required: true
    has_one :workgroup, through: :stop_area_referential

    alias_method :referential, :stop_area_referential

    # Must be defined before ObjectidSupport
    before_validation :define_stop_area_referential, on: :create
  end

  private

  def define_stop_area_referential
    # TODO Improve performance ?
    self.stop_area_referential ||= stop_area_provider&.stop_area_referential
  end
end
