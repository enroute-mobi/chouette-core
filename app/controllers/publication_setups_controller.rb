# frozen_string_literal: true

class PublicationSetupsController < Chouette::WorkgroupController
  defaults :resource_class => PublicationSetup

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :build_export, only: %i[new create]
  before_action :export, only: %i[show edit update]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  respond_to :html

  def index
    index! do |format|
      format.html {
        @publication_setups = PublicationSetupDecorator.decorate(
          @publication_setups,
          context: {
            workgroup: workgroup
          }
        )
      }
    end
  end

  def show
    if (saved_search = saved_searches.find_by(id: params[:search_id]))
      @search = saved_search.search
    end

    show! do |format|
      format.html {
        publications_collection # to mimic inherited resources index and preload search
        @chart = @search.chart(publications_scope) if @search && @search.graphical?

        unless @chart
          @publications = PublicationDecorator.decorate(publications_collection, context: {
            workgroup: workgroup,
            publication_setup: @publication_setup
          })
        end
      }
    end
  end

  def saved_searches
    @saved_searches ||= workgroup.saved_searches.for(::Search::WorkgroupPublication)
  end

  protected

  alias resource workgroup

  def publications_scope
    @publications_scope ||= resource.publications
  end

  def publications_search
    @search ||= Search::WorkgroupPublication.from_params(params, workgroup: workgroup)
  end

  def publications_collection
    @publications_collection ||= publications_search.search(publications_scope)
  end

  private

  def build_export
    @export = build_resource.export.decorate
  end

  def export
    @export = resource.export.decorate
  end

  def publication_setup_params
    destination_options = [:id, :name, :type, :_destroy, :secret_file, :publication_setup_id, :publication_api_id]
    destination_options += Destination.descendants.map do |t|
      t.options.map do |key, value|
        # To accept an array value directly in params, a permit({key: []}) is required instead of just permit(:key)
        value.try(:[], :type)&.equal?(:array) ? Hash[key => []] : key
      end
    end.flatten

    params.require(:publication_setup).permit(
      :name,
      :enabled,
      :force_daily_publishing,
      :enable_cache,
      :priority,
      :workgroup_id,
      destinations_attributes: destination_options,
      export_options: {},
    ).tap do |publication_setup_params|
      if params[:export] && params[:export][:options] && publication_setup_params[:export_options][:type] == "Export::NetexGeneric"
        publication_setup_params[:export_options][:profile_options] =
          Hash[params[:export][:options][:profile_options].values.map{ |v| [v['key'], v['value']] }].to_json
      end
    end
  end

  def resource
    super.decorate(context: { workgroup: workgroup })
  end

  def collection
    @publication_setups ||= super.order(sort_column => sort_direction).paginate(page: params[:page]) # rubocop:disable Naming/MemoizedInstanceVariableName
  end

  def sort_column
    (PublicationSetup.column_names).include?(params[:sort]) ? params[:sort] : 'name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end
end
