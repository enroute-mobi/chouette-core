# frozen_string_literal: true

module Chouette
  class StopAreaReferentialController < WorkbenchController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    include ControllerResourceValidations

    belongs_to :stop_area_referential, singleton: true

    def stop_area_referential
      association_chain
      get_parent_ivar(:stop_area_referential)
    end
    alias current_referential stop_area_referential
    helper_method :current_referential

    protected

    def build_resource
      get_resource_ivar || set_resource_ivar(
        apply_scopes_if_available(
          stop_area_provider_for_build.send(method_for_association_chain)
        ).send(method_for_build, resource_params[0].merge(stop_area_referential: stop_area_referential))
      )
    end

    def controller_resource_validations(object)
      errors = super
      unless object.new_record? || candidate_stop_area_providers.include?(object.stop_area_provider)
        errors << %i[stop_area_provider_id invalid]
      end
      errors
    end

    def parent_for_parent_policy
      if params[:id]
        resource.stop_area_provider
      else
        stop_area_provider_for_build
      end
    end

    private

    def stop_area_provider_from_params
      return nil unless params[resource_instance_name] \
                     && params[resource_instance_name][:stop_area_provider_id].present?

      candidate_stop_area_providers.find(params[resource_instance_name][:stop_area_provider_id])
    end

    def stop_area_provider_for_build
      @stop_area_provider_for_build ||= stop_area_provider_from_params || current_workbench.default_stop_area_provider
    end

    def candidate_stop_area_providers
      @candidate_stop_area_providers ||= current_workbench.stop_area_providers.order(:name)
    end
    helper_method :candidate_stop_area_providers
  end
end
