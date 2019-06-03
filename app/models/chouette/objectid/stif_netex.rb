module Chouette
  module Objectid
    class StifNetex < Chouette::Objectid::Netex

      @format = Chouette::Objectid::Netex.format

      def initialize(**attributes)
        @provider_id = attributes[:provider_id] ||= 'stif'
        super
      end

      def short_id
        local_id.try(:split, "-").try(:last)
      end
    end
  end
end
