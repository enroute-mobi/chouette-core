# frozen_string_literal: true

# Define primary key via a simple sequence starting from the last id currently in DB
#
#   inserter = ReferentialInserter.new referential do |config|
#     config.add NextIdInserter
#   end
#
#   inserter.routes << Chouette::TimeTable.new
#
class NextIdInserter < IdInserter
  # :nodoc:
  class Base < ::IdInserter::Base
    def initialize(model_class, _parent_inserter)
      super
      @model_class = model_class
      @next_primary_key = last_id
    end

    def flush
      @next_primary_key = last_id
    end

    private

    def last_id
      @model_class.maximum(:id) || 0
    end
  end
end
