class PublicationSetupsController < ChouetteController
  include PolicyChecker

  defaults :resource_class => PublicationSetup
  belongs_to :workgroup

  before_action :build_export, only: %i[show new create edit update]

  respond_to :html

  def index
    index! do |format|
      format.html {
        @publication_setups = decorate_publication_setups(@publication_setups)
      }
    end
  end

  def show
    show! do |format|
      format.html {
        @publications = PublicationDecorator.decorate(
          @publication_setup.publications.order('created_at DESC').paginate(page: params[:page]),
          context: {
            workgroup: @workgroup,
            publication_setup: @publication_setup
          }
        )

        @export = @export.decorate
      }
    end
  end

  private

  def build_export
    @export = build_resource.export.decorate
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
      :workgroup_id,
      destinations_attributes: destination_options,
      export_options: {}
    )
  end

  def resource
    super.decorate(context: { workgroup: parent })
  end

  def collection
    @q = end_of_association_chain.ransack(params[:q])
    scope = @q.result(distinct: true)
    scope = scope.order(sort_column + ' ' + sort_direction)
    @publication_setups = scope.paginate(page: params[:page])
  end

  def sort_column
    (PublicationSetup.column_names).include?(params[:sort]) ? params[:sort] : 'name'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def decorate_publication_setups publication_setups
    PublicationSetupDecorator.decorate(
      publication_setups,
      context: {
        workgroup: parent
      }
    )
  end
end
