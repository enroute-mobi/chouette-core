# frozen_string_literal: true

class ExportsController < Chouette::WorkbenchController
  include Downloadable

  defaults resource_class: Export::Base, collection_name: 'exports', instance_name: 'export'

  skip_before_action :authenticate_user!, only: [:upload]
  skip_before_action :verify_authenticity_token, only: [:upload]
  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, except: %i[new create index show upload download]
  # rubocop:enable Rails/LexicallyScopedActionFilter
  before_action :load_referentials, only: %i[new create]

  # FIXME See CHOUETTE-207
  def upload
    resource = Export::Base.find params[:id]
    if params[:token] == resource.token_upload
      resource.file = params[:file]
      resource.save!
      render json: {status: :ok}
    else
      user_not_authorized
    end
  end

  def show
    @export = resource.decorate(context: { parent: parent })
    respond_to do |format|
      format.html
      format.json do
        fragment = render_to_string(partial: 'exports/show', formats: :html)
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
        @exports = decorate_collection(collection)
      end
    end
  end

  def download
    prepare_for_download resource
    send_file resource.file.path, filename: resource.user_file.name, type: resource.user_file.content_type
  end

  def create
    create! { [parent, resource] }
  end

  protected

  # rubocop:disable Naming/MemoizedInstanceVariableName
  def resource
    @export ||= parent.exports.find(params[:id])
  end

  def build_resource
    @export ||= Export::Base.new(*resource_params) do |export|
      export.workbench = workbench
      export.workgroup = workbench.workgroup
      export.creator   = current_user.name
    end.decorate
  end
  # rubocop:enable Naming/MemoizedInstanceVariableName

  def scope
    parent.exports
  end

  def search
    @search ||= Search.from_params(params)
  end

  def collection
    @collection ||= search.search(scope)
  end

  def export_params
    params.require(:export).permit(:name, :type, :referential_id, :notification_target, options: {}).tap do |export_params|
      export_params[:workbench_id] = workbench.id
      export_params[:creator] = current_user.name
      export_params[:user_id] = current_user.id
      if export_params[:options] && export_params[:options][:profile_options] && export_params[:type] == "Export::NetexGeneric"
        export_params[:options][:profile_options] = Hash[export_params[:options][:profile_options].values.map{ |v| [v['key'], v['value']] }].to_json
      end
    end
  end

  def decorate_collection(exports)
    ExportDecorator.decorate(
      exports,
      context: {
        parent: parent
      }
    )
  end

  class Search < Search::Operation
    def query_class
      Query::Export
    end
  end

  def load_referentials
    referential_ids = parent.referentials.exportable.pluck(:id)
    referential_ids += workbench.workgroup.output.referentials.pluck(:id)

    @referential_options = Rabl::Renderer.new(
      'autocomplete/referentials',
      Referential.where(id: referential_ids).order('created_at desc'),
      format: :hash,
      view_path: 'app/views'
    ).render
  end
end
