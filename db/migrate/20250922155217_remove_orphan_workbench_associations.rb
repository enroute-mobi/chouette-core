# frozen_string_literal: true

class RemoveOrphanWorkbenchAssociations < ActiveRecord::Migration[7.0]
  def up # rubocop:disable Metrics/MethodLength
    on_public_schema_only do
      DocumentProvider.left_outer_joins(:workbench)
                      .where(workbenches: { id: nil })
                      .includes(:documents)
                      .find_each do |document_provider|
        document_provider.documents.each(&:destroy)
        document_provider.destroy # unfortunately, document_provider.documents.exists? will be called
      end

      Contract.left_outer_joins(:workbench).where(workbenches: { id: nil }).find_each(&:destroy)
      Contract.where(company_id: nil).find_each(&:destroy)

      Sequence.left_outer_joins(:workbench).where(workbenches: { id: nil }).find_each(&:destroy)
    end
  end
end
