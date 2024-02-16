module Chouette
  class Contract < Chouette::ActiveRecord
    include CodeSupport

    belongs_to :company, required: true

    has_many :lines
  end
end
