# frozen_string_literal: true

module Chouette
  class TopologicReferentialController < WorkbenchController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    include ControllerResourceValidations

    belongs_to :shape_referential, singleton: true

    def shape_referential
      association_chain
      get_parent_ivar(:shape_referential)
    end
    alias current_referential shape_referential
    helper_method :current_referential

    protected

    def build_resource
      get_resource_ivar || set_resource_ivar(
        apply_scopes_if_available(
          shape_provider_for_build.send(method_for_association_chain)
        ).send(method_for_build, resource_params[0].merge(shape_referential: shape_referential))
      )
    end

    def controller_resource_validations(object)
      errors = super
      unless object.new_record? || candidate_shape_providers.include?(object.shape_provider)
        errors << %i[shape_provider_id invalid]
      end
      errors
    end

    def parent_for_parent_policy
      if params[:id]
        resource.shape_provider
      else
        shape_provider_for_build
      end
    end

    private

    def shape_provider_from_params
      return nil unless params[resource_instance_name] && params[resource_instance_name][:shape_provider_id].present?

      candidate_shape_providers.find(params[resource_instance_name][:shape_provider_id])
    end

    def shape_provider_for_build
      @shape_provider_for_build ||= shape_provider_from_params || current_workbench.default_shape_provider
    end

    def candidate_shape_providers
      @candidate_shape_providers ||= current_workbench.shape_providers.order(:short_name)
    end
    helper_method :candidate_shape_providers
  end
end
