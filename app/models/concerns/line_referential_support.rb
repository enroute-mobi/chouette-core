# frozen_string_literal: true

module LineReferentialSupport
  extend ActiveSupport::Concern

  included do
    belongs_to :line_referential, required: true
    belongs_to :line_provider, required: true

    alias_method :referential, :line_referential

    # Must be defined before ObjectidSupport
    before_validation :define_line_referential, on: :create
  end

  def workgroup
    @workgroup ||= CustomFieldsSupport.current_workgroup ||
                   Workgroup.where(line_referential_id: line_referential_id).last
  end

  def line_referential_id=(_)
    r = super
    @workgroup = nil
    r # rubocop:disable Lint/Void
  end

  def reload(*)
    r = super
    @workgroup = nil
    r
  end

  private

  def define_line_referential
    # TODO: Improve performance ?
    self.line_referential ||= line_provider&.line_referential
  end
end
