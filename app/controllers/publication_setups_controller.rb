class PublicationSetupsController < ChouetteController
  include PolicyChecker

  requires_feature :manage_publications

  defaults :resource_class => PublicationSetup
  belongs_to :workgroup

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
      }
    end
  end

  private

  def publication_setup_params
    export_options = []
    export_class = params[:publication_setup][:export_type] && params[:publication_setup][:export_type].safe_constantize
    if export_class
      export_options = export_class.options.keys
    end

    destination_options = [:id, :name, :type, :_destroy, :secret_file, :publication_setup_id, :publication_api_id]
    destination_options += Destination.descendants.map{ |t| t.options.keys }.flatten

    params.require(:publication_setup).permit(
      :name,
      :export_type,
      :enabled,
      :workgroup_id,
      export_options: export_options,
      destinations_attributes: destination_options
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
