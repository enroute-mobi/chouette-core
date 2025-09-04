# frozen_string_literal: true

class ApplicationStoreModel
  include StoreModel::Model
  include ActiveModel::Naming

  class << self
    attr_accessor :abstract_class
    alias abstract_class? abstract_class

    def inherited(base)
      attribute :type, :string unless abstract_class? || attribute_names.include?('type')

      super
    end

    def one_of_descendants
      @one_of_descendants ||= StoreModel.one_of do |json|
        @descendants_names ||= descendants.map(&:name)

        type = json[:type] || json['type']
        if @descendants_names.include?(type)
          type.constantize
        else
          self
        end
      end
    end

    # inspired by ActiveRecord::Inheritannce
    def descends_from_application_store_model?
      return @descends_from_application_store_model if defined?(@descends_from_application_store_model)

      @descends_from_application_store_model = if superclass == ApplicationStoreModel
                                                 true
                                               elsif self == ApplicationStoreModel || !superclass.abstract_class?
                                                 false
                                               else
                                                 superclass.descends_from_application_store_model?
                                               end
    end
  end

  self.abstract_class = true

  def initialize(*)
    super
    ensure_proper_type
  end

  def becomes(klass)
    klass.new.tap do |became|
      became.instance_variable_set(:@attributes, @attributes)
      became.errors.copy!(errors)
      became.parent = parent
    end
  end

  private

  def ensure_proper_type
    self.type ||= self.class.name unless self.class.descends_from_application_store_model?
  end

  class IntegerArrayType < ActiveRecord::Type::Value
    def initialize(**options)
      super
      @integer_type = ActiveRecord::Type::Integer.new(**options)
    end

    def cast(value)
      case value
      when ::Array
        value.map { |v| @integer_type.cast(v) }
      when ::String
        cast(ActiveSupport::JSON.decode(value))
      end
    end
  end
end
