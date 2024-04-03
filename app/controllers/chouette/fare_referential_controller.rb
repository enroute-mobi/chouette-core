# frozen_string_literal: true

module Chouette
  class FareReferentialController < WorkbenchController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    include ControllerResourceValidations

    protected

    def build_resource
      get_resource_ivar || set_resource_ivar(
        apply_scopes_if_available(
          fare_provider_for_build.send(method_for_association_chain)
        ).send(method_for_build, resource_params[0])
      )
    end

    def controller_resource_validations(object)
      errors = super
      unless object.new_record? || candidate_fare_providers.include?(object.fare_provider)
        errors << %i[fare_provider_id invalid]
      end
      errors
    end

    def parent_for_parent_policy
      if params[:id]
        resource.fare_provider
      else
        fare_provider_for_build
      end
    end

    private

    def fare_provider_from_params
      return nil unless params[resource_instance_name] && params[resource_instance_name][:fare_provider_id].present?

      candidate_fare_providers.find(params[resource_instance_name][:fare_provider_id])
    end

    def fare_provider_for_build
      @fare_provider_for_build ||= fare_provider_from_params || current_workbench.default_fare_provider
    end

    def candidate_fare_providers
      @candidate_fare_providers ||= current_workbench.fare_providers.order(:name)
    end
    helper_method :candidate_fare_providers
  end
end
