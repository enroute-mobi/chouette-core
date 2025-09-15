# frozen_string_literal: true

class PublicationsController < Chouette::WorkgroupController
  defaults :resource_class => Publication
  belongs_to :publication_setup, optional: true

  before_action :find_publication_setup!, only: %i[create show]

  respond_to :html

  def index
    if (saved_search = saved_searches.find_by(id: params[:search_id]))
      @search = saved_search.search
    end

    index! do |format|
      format.html {
        @chart = @search.chart(scope) if @search && @search.graphical?

        unless @chart
          @publications = decorate_publication(collection.includes(:publication_setup))
        end
      }
    end
  end

  def create
    referential = @workgroup.output.current

    @publication = publication_setup.publish(referential, creator: current_user.name)
    @publication.enqueue

    redirect_to workgroup_publication_setup_path(@workgroup, publication_setup)
  end

  def show
    @export = ExportDecorator.decorate(
      publication.export,
      context: {
        parent: workgroup
      }
    )
    show!
  end

  def saved_searches
    @saved_searches ||= workgroup.saved_searches.for(::Search::WorkgroupPublication)
  end

  protected

  alias publication resource
  alias publication_setup parent

  def scope
    @scope ||= workgroup.publications
  end

  def search
    @search ||= Search::WorkgroupPublication.from_params(params, workgroup: workgroup)
  end

  def collection
    @publications ||= search.search(scope)
  end

  def find_publication_setup!
    parent || raise(ActiveRecord::RecordNotFound)
  end

  private

  def decorate_publication(publications)
    PublicationDecorator.decorate(
      publications,
      context: {
        workgroup: workgroup
      }
    )
  end
end
