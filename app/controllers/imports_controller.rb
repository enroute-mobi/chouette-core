# frozen_string_literal: true

class ImportsController < Chouette::WorkbenchController
  include Downloadable
  include ImportMessages

  defaults resource_class: Import::Base, collection_name: 'imports', instance_name: 'import'

  # rubocop:disable Rails/LexicallyScopedActionFilter
  skip_before_action :authenticate_user!, only: [:internal_download]
  before_action :authorize_resource, except: %i[new create index show download internal_download messages]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  respond_to :json, :html

  def internal_download
    resource = Import::Base.find params[:id]
    if params[:token] == resource.token_download
      prepare_for_download resource
      send_file resource.file.path
    else
      user_not_authorized
    end
  end

  def download
    prepare_for_download resource
    send_file resource.file.path, filename: resource.user_file.name, type: resource.user_file.content_type
  end

  def show
    @import = resource.decorate(context: { parent: parent })

    if resource.is_a?(Import::Workbench)
      @imported_resources = resource.first_child&.resources || Import::Resource.none
      if resource.first_child.is_a?(Import::Netex)
        @imported_resources = @imported_resources.where(resource_type: 'file')
      end
      @macro_list_runs = resource.macro_list_runs
      @control_list_runs = resource.control_list_runs.includes(processing: :processing_rule)
    end

    respond_to do |format|
      format.html
      format.json do
        fragment = render_to_string(partial: "imports/#{@import.short_type}", formats: :html)
        render json: { fragment: fragment }
      end
    end
  end

  def index # rubocop:disable Metrics/MethodLength
    if (saved_search = saved_searches.find_by(id: params[:search_id]))
      @search = saved_search.search(Search::Import.attributes_from_params(params))
    end

    index! do |format|
      format.html do
        @chart = @search.chart(scope) if @search.graphical?

        unless @chart
          @contextual_cols = []
          @contextual_cols << TableBuilderHelper::Column.new(
            key: :tags,
            attribute: Proc.new { |import| import.tags.map(&:name).join(', ') if import.tags.any? },
            sortable: false
          )
          @contextual_cols << TableBuilderHelper::Column.new(key: :creator, attribute: 'creator')
          @imports = decorate_collection(collection)
        end
      end
    end
  end

  def create
    create! { [parent, resource] }
  end

  def saved_searches
    @saved_searches ||= workbench.saved_searches.for(::Search::Import)
  end

  protected

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def resource
    @import ||= parent.imports.find(params[:id])
  end

  def build_resource
    @import ||= Import::Workbench.new(*resource_params) do |import|
      import.workbench = parent
      import.creator   = current_user.name
    end
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def scope
    parent.imports.where(type: 'Import::Workbench')
  end

  def search
    @search ||= ::Search::Import.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search(scope)
  end

  def import_params
    permitted_keys = %i[name file type referential_id code_space_id notification_target]
    permitted_keys += Import::Workbench.options.keys

    params.require(:import).permit(permitted_keys).tap do |import_params|
      import_params[:user_id] ||= current_user.id
      import_params[:override_internal_identifiers] = 'true' if has_feature?('import_netex_force_override_objectid')
      if (tags = params[:import][:tags]).is_a?(Array)
        import_params[:taggings_attributes] = tags.reject(&:blank?).map { |tag| { tag_id: tag } }
      end
    end
  end

  def decorate_collection(imports)
    ImportDecorator.decorate(
      imports,
      context: {
        parent: parent
      }
    )
  end

  def workgroup_context?
    false
  end

  helper_method :workgroup_context?
end
