# frozen_string_literal: true

# Define primary key via a simple sequence
#
#   inserter = ReferentialInserter.new referential do |config|
#     config.add IdInserter
#   end
#
#   inserter.routes << Chouette::TimeTable.new
#
class IdInserter < ByClassInserter
  def initialize(_target, _options = {})
    super()
  end

  def new_inserter_for(model_class)
    if with_primary_key?(model_class)
      super model_class
    else
      null_inserter
    end
  end

  def with_primary_key?(model_class)
    model_class.column_names.include? "id"
  end

  def null_inserter
    @null_inserter ||= Null.new
  end

  # Used by class without primary key
  class Null
    def insert(_model, _options = {}); end

    def flush; end
  end

  # :nodoc:
  class Base
    def initialize(model_class, _parent_inserter)
      @model_class = model_class
      @next_primary_key = last_id
    end

    def insert(model, _options = {})
      model.id = next_primary_key
    end

    def flush
      @next_primary_key = last_id
    end

    private

    def next_primary_key
      @next_primary_key += 1
    end

    def last_id
      @model_class.maximum(:id) || 0
    end
  end
end
