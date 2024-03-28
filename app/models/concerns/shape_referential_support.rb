# frozen_string_literal: true

module ShapeReferentialSupport
  extend ActiveSupport::Concern

  included do
    belongs_to :shape_referential, required: true
    belongs_to :shape_provider, required: true

    alias_method :referential, :shape_referential

    # Must be defined before ObjectidSupport
    before_validation :define_shape_referential, on: :create

    # TODO May be usefull, but must not impact performance
    # validates :shape_provider, inclusion: { in: ->(shape) { shape.shape_referential.shape_providers } }, if: :shape_referential
  end

  private

  def define_shape_referential
    # TODO: Improve performance ?
    self.shape_referential ||= shape_provider&.shape_referential
  end
end
