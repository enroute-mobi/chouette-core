module Chouette
  class TridentActiveRecord < Chouette::ActiveRecord

    self.abstract_class = true

    def hub_restricted?
      referential.data_format == "hub"
    end

    def prefix
      referential.prefix
    end
  end
end
