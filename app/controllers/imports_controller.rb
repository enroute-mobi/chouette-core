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
    respond_to do |format|
      format.html
      format.json do
        fragment = render_to_string(partial: "imports/#{@import.short_type}", formats: :html)
        render json: { fragment: fragment }
      end
    end
  end

  def index
    index! do |format|
      format.html do
        # if collection.out_of_bounds?
        #   redirect_to params.merge(:page => 1)
        # end
        @contextual_cols = []
        @contextual_cols << TableBuilderHelper::Column.new(key: :creator, attribute: 'creator')
        @imports = decorate_collection(collection)
      end
    end
  end

  def create
    create! { [parent, resource] }
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
    @search ||= Search.from_params(params)
  end

  def collection
    @collection ||= search.search(scope)
  end

  def import_params
    permitted_keys = %i(name file type referential_id code_space_id notification_target)
    permitted_keys += Import::Workbench.options.keys
    import_params = params.require(:import).permit(permitted_keys)
    import_params[:user_id] ||= current_user.id
    import_params
  end

  def decorate_collection(imports)
    ImportDecorator.decorate(
      imports,
      context: {
        parent: parent
      }
    )
  end

  class Search < Search::Operation
    def query_class
      Query::Import
    end
  end
end
