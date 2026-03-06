# frozen_string_literal: true

# Base class for ActiveRecord stored into a Referential
class Referential
  class ActiveRecord < Chouette::ActiveRecord
    include TransientSupport

    acts_as_copy_target

    self.abstract_class = true

    class << self
      attr_reader :current_workgroup

      def current_referential
        Referential.where(slug: Apartment::Tenant.current).first!
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

    delegate :prefix, to: :referential

    # optional_on
    #
    # :optional_on mixes the :optional with the validation :on option.
    # It tests the belongs_to presence unless the validation context is the given on
    #
    # skippable
    #
    # When :skippable is true, the belongs_to presence is not validated
    # if skip_presence_of has been used on this attribute
    #
    def self.belongs_to(name, scope = nil, skippable: false, optional_on: nil, **options)
      if skippable || optional_on
        options[:optional] = true

        unless_condition = proc do
          skippable && skip_presence_of?(name) ||
            optional_on && validation_context == optional_on
        end

        validates name, presence: true, unless: unless_condition
      end

      super name, scope, **options
    end

    def skipped_presence_of_attributes
      @skipped_presence_of_attributes ||= Set.new
    end

    def skip_presence_of(*attributes)
      skipped_presence_of_attributes.merge(attributes.flatten.map(&:to_sym))
      self
    end
    alias skipping_presence_of skip_presence_of

    def skip_presence_of?(attribute)
      skipped_presence_of_attributes.include?(attribute.to_sym)
    end
  end
end
