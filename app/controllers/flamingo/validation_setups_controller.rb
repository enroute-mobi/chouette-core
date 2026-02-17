# frozen_string_literal: true

module Flamingo
  class ValidationSetupsController < Chouette::WorkgroupController
    defaults resource_class: Flamingo::ValidationSetup,
             collection_name: :flamingo_validation_setups,
             instance_name: 'flamingo_validation_setup'

    def collection_name
      resources_configuration[:self][:collection_name]
    end

    protected

    def collection
      get_collection_ivar || set_collection_ivar(
        Flamingo::ValidationSetupDecorator.decorate(
          super.order(:name).paginate(page: params[:page]),
          context: {
            workgroup: workgroup
          }
        )
      )
    end

    def resource
      get_resource_ivar || set_resource_ivar(super.decorate(context: { workgroup: workgroup }))
    end

    def flamingo_validation_setup_params
      params.require(:flamingo_validation_setup).permit(:name, :ruleset, :include_schema, :schema_version, :ignored_schema_rules, :token)
    end

    def resource_url
      workgroup_flamingo_validation_setup_url(@workgroup, get_resource_ivar)
    end

    def collection_url
      workgroup_flamingo_validation_setups_url(@workgroup)
    end
  end
end
