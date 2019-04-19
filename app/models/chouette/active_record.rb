#require "active_record"
require 'deep_cloneable'
module Chouette
  class ActiveRecord < ::ApplicationModel

    self.abstract_class = true
    before_save :nil_if_blank, :set_data_source_ref

    # to be overridden to set nullable attrs when empty
    def self.nullable_attributes
      []
    end

    def nil_if_blank
      self.class.nullable_attributes.each { |attr| self[attr] = nil if self[attr].blank? }
    end

    def human_attribute_name(*args)
      self.class.human_attribute_name(*args)
    end

    def set_data_source_ref
      if self.respond_to?(:data_source_ref)
        self.data_source_ref ||= 'DATASOURCEREF_EDITION_BOIV'
      end
    end

    def self.model_name
      ActiveModel::Name.new self, Chouette, self.name.demodulize
    end

    class << self
      def current_referential
        Referential.where(slug: Apartment::Tenant.current).first!
      end

      def within_workgroup workgroup
        raise "Already in another workgroup: #{@@current_workgroup.inspect}" if class_variable_defined?('@@current_workgroup') && @@current_workgroup && workgroup != @@current_workgroup

        @@current_workgroup = workgroup
        value = nil
        begin
          value = yield
        ensure
          @@current_workgroup = nil
        end
        value
      end

      def current_workgroup
        @@current_workgroup
      end
    end

    def referential
      @referential ||= self.class.current_referential
    end

    def referential_slug
      Apartment::Tenant.current
    end

    def workgroup
      self.class.current_workgroup || referential&.workgroup
    end
  end
end
