class ExportsController < ChouetteController
  include PolicyChecker
  include Downloadable

  skip_before_action :authenticate_user!, only: [:upload]
  skip_before_action :verify_authenticity_token, only: [:upload]
  defaults resource_class: Export::Base, collection_name: 'exports', instance_name: 'export'
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
        fragment = render_to_string(partial: "exports/show", formats: :html)
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
        @contextual_cols << if workbench
                              TableBuilderHelper::Column.new(key: :creator, attribute: 'creator')
                            else
                              TableBuilderHelper::Column.new(
                                key: :workbench,
                                name: Workbench.ts.capitalize,
                                attribute: proc { |n| n.workbench.name },
                                link_to: lambda do |export|
                                  policy(export.workbench).show? ? export.workbench : nil
                                end
                              )
                            end
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

  def parent
    @parent ||= workgroup || workbench
  end

  def workbench
    return unless params[:workbench_id]

    @workbench ||= current_organisation&.workbenches&.find(params[:workbench_id])
  end

  def workgroup
    return unless params[:workgroup_id]

    @workgroup ||= current_organisation&.workgroups.owned&.find(params[:workgroup_id])
  end

  def resource
    @export ||= parent.exports.find(params[:id])
  end

  def build_resource
    @export ||= Export::Base.new(*resource_params) do |export|
      export.workbench = workbench
      export.workgroup = workgroup || workbench&.workgroup
      export.creator   = current_user.name
    end.decorate
  end

  def scope
    parent.exports
  end

  def search
    @search ||= Search.new(scope, params, workgroup: workgroup)
  end

  delegate :collection, to: :search

  def export_params
    params.require(:export).permit(:name, :type, :referential_id, :notification_target, options: {}).tap do |export_params|
      export_params[:workbench_id] = workbench&.id
      export_params[:workgroup_id] = workgroup&.id || workbench&.workgroup&.id
      export_params[:creator] = current_user.name
      export_params[:user_id] = current_user.id
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
    referential_ids += (workgroup || workbench&.workgroup).output.referentials.pluck(:id)

    @referential_options = Rabl::Renderer.new(
      'autocomplete/referentials',
      Referential.where(id: referential_ids).order("created_at desc"),
      format: :hash,
      view_path: 'app/views'
    ).render
  end
end
