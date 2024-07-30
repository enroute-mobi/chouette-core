# frozen_string_literal: true

module Search
  class AbstractImport < ::Search::Operation
    def query_class
      Query::Import
    end
  end
end
