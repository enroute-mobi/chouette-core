# frozen_string_literal: true

module CodeSupport
  extend ActiveSupport::Concern

  included do
    has_many :codes, as: :resource, dependent: :delete_all do
      def code_values(code_space)
        return [] unless code_space

        if loaded?
          select { |code| code.code_space == code_space }.map(&:value)
        else
          where(code_space: code_space).pluck(&:value)
        end
      end
    end
    accepts_nested_attributes_for :codes, allow_destroy: true, reject_if: :all_blank
    validates_associated :codes

    scope :by_code, ->(code_space, value) { joins(:codes).where(codes: { code_space: code_space, value: value }) }
    scope :with_code, ->(code_space) { joins(:codes).where(codes: { code_space_id: code_space }).distinct }
    scope :without_code, ->(code_space) { where.not(id: joins(:codes).where(codes: { code_space_id: code_space })) }

    validate :validate_codes

    #
    # provider.stop_areas.first_or_initialize_by_code code_space, "A"
    #
    def self.first_or_initialize_by_code(code_space, value)
      by_code(code_space, value).first_or_initialize do |model|
        model.codes = [Code.new(code_space: code_space, value: value)]
        yield model if block_given?
      end
    end

    #
    # provider.stop_areas.first_or_create_by_code code_space, "A"
    #
    def self.first_or_create_by_code(code_space, value)
      by_code(code_space, value).first_or_create do |model|
        model.codes = [Code.new(code_space: code_space, value: value)]
        yield model if block_given?
      end
    end

    def self.code_table
      Code.arel_table
    end
  end

  def validate_codes
    return if Validator::CodeSpaceUniqueness.new(codes).valid? &&
              Validator::ValueUniqueness.new(codes).valid?

    errors.add(:codes, :invalid)
  end

  module Validator
    class Base
      def initialize(codes)
        @codes = codes
      end
      attr_reader :codes

      def valid?
        validate
      end
    end

    class CodeSpaceUniqueness < Base
      def validate
        return true if duplicated_codes.empty?

        duplicated_codes.each do |code|
          code.errors.add(:value, :duplicate_code_spaces_in_codes, code_space: code.code_space.short_name)
        end

        false
      end

      def duplicated_codes
        codes
          .reject { |code| code.code_space.allow_multiple_values }
          .group_by(&:code_space_id)
          .flat_map { |_, codes| codes.many? ? codes : [] }
      end
    end

    class ValueUniqueness < Base
      def validate
        return true if duplicated_codes.empty?

        duplicated_codes.each do |code|
          code.errors.add(:value, :duplicate_values_in_codes)
        end

        false
      end

      def duplicated_codes
        codes
          .group_by { |code| [code.code_space_id, code.value] }
          .flat_map { |_, codes| codes.many? ? codes : [] }
      end
    end
  end

  def code_values
    codes.joins(:code_space)
         .select('code_spaces.short_name', :code_space_id, :value, :id)
         .map(&:attributes)
  end

  def assign_state_codes(state_codes) # rubocop:disable Metrics/MethodLength
    codes_by_id = codes.index_by(&:id)

    state_codes.each do |code|
      next unless value = code['value']
      attributes = {
        code_space_id: code['code_space_id'],
        value: value
      }
      if id = code['id']
        codes_by_id.delete(id)&.attributes = attributes
      else
        codes.new(attributes)
      end
    end

    codes_by_id.each_value(&:mark_for_destruction)
  end
end
