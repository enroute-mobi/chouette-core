# frozen_string_literal: true

class PublicationSetupsController < Chouette::WorkgroupController
  include ExportSetupControllerSupport

  defaults :resource_class => PublicationSetup

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

  protected

  alias resource workgroup

  private

  def publication_setup_params # rubocop:disable Metrics/MethodLength
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
      :export_type,
      export_setup: {},
      destinations_attributes: destination_options
    ).tap do |publication_setup_params|
      parse_export_setup_netex_profile_options!(publication_setup_params, :export_type, :export_setup)
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
