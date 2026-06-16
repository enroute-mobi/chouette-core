# frozen_string_literal: true

module Search
  class WorkgroupPublication < ::Search::Operation
    attribute :text
    attribute :publication_setup_id
    attribute :export_type
    attr_accessor :workgroup

    def searched_class
      ::Publication
    end

    def query(scope)
      super(scope)
        .publication_setup_id(publication_setup_id)
        .export_type(export_type)
        .text(text)
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

    class Order < ::Search::Operation::Order
      attributes.delete_if { |attribute| attribute.name == :status }
      attribute :status, column: 'user_status'
      attribute :publication_setup, joins: :publication_setup, column: 'publication_setups.name'
      attribute :export_type,
                joins: :publication_setup,
                column: Arel.sql("publication_setups.export_setup->>'type'")
    end
  end
end
