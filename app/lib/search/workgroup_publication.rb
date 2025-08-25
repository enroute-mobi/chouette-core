# frozen_string_literal: true

module Search
  class WorkgroupPublication < ::Search::Operation
    attr_accessor :workgroup

    def searched_class
      ::Publication
    end

    def query_class
      Query::WorkgroupPublication
    end
  end
end
