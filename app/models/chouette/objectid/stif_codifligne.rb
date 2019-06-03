module Chouette
  module Objectid
    class StifCodifligne < Chouette::Objectid::Netex

      attr_accessor :sync_id
      attr_accessor :local_marker
      validates :creation_id, presence: false

      @format = /^([0-9A-Za-z_-]+):([A-Za-z]+):([0-9A-Za-z_-]+):([0-9A-Za-z_-]*)$/

      def initialize(**attributes)
        @provider_id = attributes[:provider_id]
        @object_type = attributes[:object_type]
        @local_id = attributes[:local_id]
        @sync_id = attributes[:sync_id]
        @local_marker = attributes[:local_marker]
        super
      end

      def to_s
        if sync_id.present?
          "#{provider_id}:#{sync_id}:#{object_type}:#{local_id}"
        else
          "#{provider_id}:#{object_type}:#{local_id}:#{local_marker}"
        end
      end

      def short_id
        local_id
      end
    end
  end
end
