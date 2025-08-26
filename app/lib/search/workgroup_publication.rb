# frozen_string_literal: true

module Search
  class WorkgroupPublication < ::Search::Operation
    attribute :publication_setup_id
    attr_accessor :workgroup

    def searched_class
      ::Publication
    end

    def query(scope)
      super(scope).publication_setup_id(publication_setup_id)
    end

    def query_class
      Query::Publication
    end

    def candidate_publication_setup
      workgroup.publication_setups.order(:name)
    end
  end
end
