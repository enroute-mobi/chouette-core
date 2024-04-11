# frozen_string_literal: true

class SourcesController < Chouette::WorkbenchController
  include ApplicationHelper

  defaults :resource_class => Source

  before_action :decorate_source, only: [:show, :new, :edit]
  after_action :decorate_source, only: [:create, :update]

  before_action :source_params, only: [:create, :update]

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
            workbench: workbench
          }
        )
      end
    end
  end

  def show
    @retrievals = @source.retrievals.order(started_at: :desc).limit(20)
  end

  def retrieve
    source = workbench.sources.find(params[:id])
    source.retrieve

    redirect_to action: :show
  end

  protected

  def collection
    @sources = parent.sources.paginate(page: params[:page], per_page: 30)
  end

  private

  def decorate_source
    object = resource rescue build_resource
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
      :import_option_update_workgroup_providers,
      :import_option_store_xml,
      :import_option_disable_missing_resources,
      :import_option_strict_mode,
      :import_option_line_provider_id,
      :import_option_stop_area_provider_id,
      :created_at,
      :updated_at,
      :downloader_type,
      :downloader_option_raw_authorization,
      :retrieval_time_of_day,
      :retrieval_frequency,
      retrieval_days_of_week_attributes: [:monday, :tuesday, :wednesday, :thursday, :friday, :saturday, :sunday],
      import_option_process_gtfs_route_ids: []
    ).with_defaults(workbench_id: workbench.id)
  end
end
