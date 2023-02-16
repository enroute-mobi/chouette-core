# frozen_string_literal: true

module Fare
  # Regroups several Fare models into a Workbench
  class Validity < ApplicationModel
    self.table_name = :fare_validities

    belongs_to :fare_provider, class_name: 'Fare::Provider', optional: false
    has_one :fare_referential, through: :fare_provider
    has_one :workbench, through: :fare_provider

    include CodeSupport

    has_many :product_validities, class_name: 'Fare::ProductValidity', foreign_key: 'fare_validity_id'
    has_many :products, through: :product_validities
    # foreign_key: 'fare_validity_id', association_foreign_key: 'fare_product_id'

    validates :name, :products, :expression, presence: true
    validates_associated :expression

    def scope
      @scope ||= Expression::Scope.new(workbench)
    end

    def expression
      super&.with_scope(scope)
    end

    module Expression
      class Type < ActiveRecord::Type::Value
        def serialize(expression)
          return nil unless expression

          expression.to_json
        end

        def deserialize(json)
          Expression::Base.parse_json(json) if json
        end

        def changed_in_place?(raw_old_value, new_value)
          deserialize(raw_old_value) != new_value
        end
      end

      class Scope
        def initialize(workbench)
          @workbench = workbench
        end

        delegate :lines, to: :workbench

        delegate :fare_zones, to: :fare_referential

        def fare_referential
          @fare_referential ||= workbench.workgroup.fare_referential
        end

        private

        attr_reader :workbench
      end

      class Base
        include ActiveModel::Model

        def with_scope(scope)
          self.scope = scope

          self
        end

        attr_accessor :scope

        def as_json(options = {})
          super(options).tap do |attributes|
            attributes['type'] = self.class.name.demodulize.underscore
            attributes.except! 'scope', 'validation_context', 'errors'
          end
        end

        def self.parse_json(json)
          from_json(JSON.parse(json))
        end

        def self.from_json(hash)
          return nil if hash.blank?

          # {type: "composite", expressions: [] }
          # {type: "Line", line_id: 42 }

          type = hash.delete('type')&.classify
          Fare::Validity::Expression.const_get(type).new(hash)
        end
      end

      class Composite < Base
        def logical_link
          :and
        end

        def scope=(scope)
          @scope = scope
          expressions.each { |expression| expression.scope = scope }
        end

        def expressions
          @expressions ||= []
        end

        def expressions=(expressions)
          @expressions = expressions.map do |expression|
            expression = Base.from_json(expression) if expression.is_a?(Hash)
            expression
          end
        end

        validates :expressions, presence: true
      end

      class Line < Base
        attr_accessor :line_id

        validates :line_id, :line, presence: true

        def line
          scope.lines.find(line_id)
        end

        def line=(line)
          self.line_id = line&.id
        end
      end

      class Zone < Base
        attr_accessor :zone_id

        validates :zone_id, :zone, presence: true

        def zone
          scope.fare_zones.find(zone_id)
        end

        def zone=(zone)
          self.zone_id = zone&.id
        end
      end

      class ZoneToZone < Base
        attr_accessor :from_id, :to_id

        # From is required unless to is defined
        validates :from_id, presence: true, unless: :to_id

        validates :from, presence: true, if: :from_id
        validates :to, presence: true, if: :to_id

        def from
          scope.fare_zones.find(from_id) if from_id
        end

        def from=(from)
          self.from_id = from&.id
        end

        def to
          scope.fare_zones.find(to_id) if to_id
        end

        def to=(to)
          self.to_id = to&.id
        end
      end
    end

    attribute :expression, Expression::Type.new
  end
end
