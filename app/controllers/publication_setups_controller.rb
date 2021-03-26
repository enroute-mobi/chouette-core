class PublicationSetupsController < ChouetteController
  include PolicyChecker

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

  def create
    attributes = publication_setup_params.merge(export_options: export_options_params || {})
    @publication_setup = PublicationSetup.create(attributes)
    @export = @publication_setup.new_export
    create! { workgroup_publication_setup_path(parent, @publication_setup) }
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
    destination_options = [:id, :name, :type, :_destroy, :secret_file, :publication_setup_id, :publication_api_id]
    destination_options += Destination.descendants.map do |t|
      t.options.map do |key, value|
        # To accept an array value directly in params, a permit({key: []}) is required instead of just permit(:key)
        value.try(:[], :type)&.equal?(:array) ? Hash[key => []] : key
      end
    end.flatten

    params.require(:publication_setup).permit(
      :name,
      :export_type,
      :enabled,
      :workgroup_id,
      destinations_attributes: destination_options
    )
  end

  def export_options_params
    permitted_keys = %i[type]
    export_class = params.dig(:publication_setup, :export_type)&.safe_constantize

    if export_class
      permitted_keys += export_class.options.keys
    end
    
    return {} unless params[:export]

    params.require(:export).permit(*permitted_keys, line_ids: [], line_provider_ids: [], company_ids: []).tap do |_params|
      if export_class&.method_defined?(:duration)
        _params[:duration] = _params[:period] == 'only_next_days' ?  _params[:duration].to_i : nil
      end
    end
  end

  def resource
    super.decorate(context: { workgroup: parent }).tap do |ps|
      @export = ps.new_export(workgroup: parent).decorate
    end
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
