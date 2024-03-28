# frozen_string_literal: true

module Chouette
  class LineReferentialController < WorkbenchController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    include ControllerResourceValidations

    belongs_to :line_referential, singleton: true

    def line_referential
      association_chain
      get_parent_ivar(:line_referential)
    end
    alias current_referential line_referential
    helper_method :current_referential

    protected

    def build_resource
      get_resource_ivar || set_resource_ivar(
        apply_scopes_if_available(
          line_provider_for_build.send(method_for_association_chain)
        ).send(method_for_build, resource_params[0].merge(line_referential: line_referential))
      )
    end

    def controller_resource_validations(object)
      errors = super
      unless object.new_record? || candidate_line_providers.include?(object.line_provider)
        errors << %i[line_provider_id invalid]
      end
      errors
    end

    def parent_for_parent_policy
      if params[:id]
        resource.line_provider
      else
        line_provider_for_build
      end
    end

    private

    def line_provider_from_params
      return nil unless params[resource_instance_name] && params[resource_instance_name][:line_provider_id].present?

      candidate_line_providers.find(params[resource_instance_name][:line_provider_id])
    end

    def line_provider_for_build
      @line_provider_for_build ||= line_provider_from_params || current_workbench.default_line_provider
    end

    def candidate_line_providers
      @candidate_line_providers ||= current_workbench.line_providers.order(:name)
    end
    helper_method :candidate_line_providers
  end
end
