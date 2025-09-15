# frozen_string_literal: true

module Search
  class WorkgroupPublication < ::Search::Operation
    attribute :creator
    attribute :publication_setup_id
    attribute :export_type
    attr_accessor :workgroup

    def searched_class
      ::Publication
    end

    def query(scope)
      super(scope).publication_setup_id(publication_setup_id).creator(creator).export_type(export_type)
    end

    def query_class
      Query::Publication
    end

    def candidate_publication_setup
      workgroup.publication_setups.order(:name)
    end

    def candidate_export_type
      workgroup.export_types.map(&:constantize)
    end
  end
end
