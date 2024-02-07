# frozen_string_literal: true

class WorkgroupOutputsController < Chouette::WorkgroupController
  respond_to :html, only: [:show]
  defaults resource_class: Workgroup

  def show
    @aggregates = workgroup.aggregates.order('created_at desc').paginate(page: params[:page], per_page: 30)
    @aggregates = AggregateDecorator.decorate(@aggregates)
  end

  Policy::Authorizer::Controller.for(self, Policy::Authorizer::Legacy)
end
