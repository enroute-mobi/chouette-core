class SourcesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

  defaults :resource_class => Source

  before_action :decorate_source, only: %i[show new edit]
  after_action :decorate_source, only: %i[create update]

  before_action :source_params, only: [:create, :update]

  belongs_to :workbench

  respond_to :html, :xml, :json

  def index
    index! do |format|
      format.html do
        if collection.out_of_bounds?
          redirect_to params.merge(:page => 1)
        end

        @sources = SourceDecorator.decorate(
          collection,
          context: {
            workbench: @workbench
          }
        )
      end
    end
  end

  protected

  alias workbench parent

  def collection
    @sources = parent.sources.paginate(page: params[:page], per_page: 30)
  end

  private

  def decorate_source
    object = source rescue build_resource
    @source = SourceDecorator.decorate(
      object,
      context: {
        workbench: workbench
      }
    )
  end

  def source_params
    params.require(:source).permit(
      :name,
      :url,
      :checksum,
      :enabled,
      :ignore_checksum,
      :notification_target,
      :import_option_automatic_merge,
      :import_option_archive_on_fail,
      :created_at,
      :updated_at,
      downloader_type: [:direct, :french_nap],
    ).with_defaults(workbench_id: parent.id)
  end
end
