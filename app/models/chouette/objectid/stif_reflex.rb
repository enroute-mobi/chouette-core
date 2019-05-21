module Chouette
  module Objectid
    class StifReflex < Chouette::Objectid::Netex

      attr_accessor :country_code
      validates :creation_id, presence: false

      @@format = /^(\w+)(:)?:([A-Za-z]+):(\d+):(?(2)(\w+))$/

      def initialize(**attributes)
        super
        @provider_id = attributes[:provider_id]
        @country_code = attributes[:country_code]
      end

      def to_s
        if country_code.present?
          "#{self.country_code}::#{self.object_type}:#{self.local_id}:#{self.provider_id}"
        else
          "#{self.provider_id}:#{self.object_type}:#{self.local_id}:"
        end
      end

      def short_id
        local_id
      end
    end
  end
end