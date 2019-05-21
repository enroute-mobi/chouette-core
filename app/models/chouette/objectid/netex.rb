module Chouette
  module Objectid
    class Netex
      include ActiveModel::Model

      attr_accessor :provider_id, :object_type, :local_id, :creation_id
      validates_presence_of :provider_id, :object_type, :local_id, :creation_id
      validate :must_respect_format

      def initialize(**attributes)
        @provider_id = attributes[:provider_id] || 'chouette'
        @object_type = attributes[:object_type]
        @local_id = attributes[:local_id]
        @creation_id = attributes[:creation_id] || 'LOC'
      end

      @@format = /^([A-Za-z_-]+):([A-Za-z]+):([0-9A-Za-z_-]+):([A-Za-z]+)$/
      cattr_reader :format

      def to_s
        "#{self.provider_id}:#{self.object_type}:#{self.local_id}:#{self.creation_id}"
      end

      def must_respect_format
        errors.add(:base, :invalid) unless self.to_s.match(self.class.format)
      end

      def short_id
        local_id.try(:split, "-").try(:first)
      end
    end
  end
end