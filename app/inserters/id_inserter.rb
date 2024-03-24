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

  # :nodoc:
  class Base
    def initialize(_model_class, _parent_inserter)
      @next_primary_key = 0
    end

    def insert(model, _options = {})
      model.id = next_primary_key
    end

    def flush; end

    private

    def next_primary_key
      @next_primary_key += 1
    end
  end
end
