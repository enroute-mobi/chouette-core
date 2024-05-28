# frozen_string_literal: true

module Chouette
  class ReferentialController < WorkbenchController
    # To prevent a "chouette_" to be added to all its chidren
    resources_configuration[:self].delete(:route_prefix)

    include ReferentialSupport

    belongs_to :referential

    # set referential before calling #association_chain
    around_action :set_current_workgroup
    # switch referential before finding resource
    # rubocop:disable Rails/LexicallyScopedActionFilter
    before_action :authorize_resource, except: %i[new create index show]
    before_action :authorize_resource_class, only: %i[new create]
    # rubocop:enable Rails/LexicallyScopedActionFilter

    def policy_context_class
      Policy::Context::Referential
    end

    private

    def workbench
      @workbench ||= begin_of_association_chain.workbenches.find(params[:workbench_id])
    end

    def current_workbench
      workbench
    rescue ::ActiveRecord::RecordNotFound
      nil
    end
  end
end
