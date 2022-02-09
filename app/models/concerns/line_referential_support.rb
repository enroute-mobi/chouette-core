module LineReferentialSupport
  extend ActiveSupport::Concern

  included do
    belongs_to :line_referential
    validates_presence_of :line_referential
    alias_method :referential, :line_referential
  end

  def workgroup
    line_referential&.workgroup
  end
end
