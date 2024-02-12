# frozen_string_literal: true

class PublicationsController < Chouette::WorkgroupController
  include PolicyChecker

  defaults :resource_class => Publication
  belongs_to :publication_setup

  respond_to :html

  before_action :decorate_exports, only: :show

  protected

  def search
    @search ||= Search::PublicationExport.from_params(params)
  end

  def collection
    @collection ||= search.search(@publication.export)
  end

  private

  def decorate_exports
    @exports = ExportDecorator.decorate(
      collection,
      context: {
        parent: workgroup
      }
    )
  end
end
