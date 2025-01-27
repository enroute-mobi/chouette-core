# frozen_string_literal: true

require 'postgresql_cursor'

module PostgreSQLCursor
  class Cursor
    # TODO: Open PR on postgresql_cursor. See CHOUETTE-4155
    # https://github.com/afair/postgresql_cursor/issues/57
    alias each_instance_original each_instance
    def each_instance(klass = nil, &block)
      each_instance_original(Instantiator.new(klass || @type), &block)
    end

    alias each_instance_batch_original each_instance_batch
    def each_instance_batch(klass = nil, &block)
      each_instance_batch_original(Instantiator.new(klass || @type), &block)
    end
  end

  class Instantiator
    def initialize(model)
      @model = model
    end

    def instantiate(row, column_types)
      @column_types ||= column_types.reject { |k, _| @model.attribute_types.key?(k) }
      @model.instantiate(row, @column_types)
    end
  end
end
