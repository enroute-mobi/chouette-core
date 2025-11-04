# frozen_string_literal: true

module LineReferentialSupport
  extend ActiveSupport::Concern

  included do
    belongs_to :line_referential # CHOUETTE-3247 required: true
    belongs_to :line_provider # CHOUETTE-3247 required: true
    has_one :workgroup, through: :line_referential

    alias_method :referential, :line_referential

    # Must be defined before ObjectidSupport
    before_validation :define_line_referential, on: :create
  end

  private

  def define_line_referential
    # TODO: Improve performance ?
    self.line_referential ||= line_provider&.line_referential
  end
end
