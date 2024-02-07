# frozen_string_literal: true

class AggregatesController < Chouette::WorkgroupController
  defaults resource_class: Aggregate

  # rubocop:disable Rails/LexicallyScopedActionFilter
  before_action :authorize_resource, only: %i[edit update destroy rollback]
  # rubocop:enable Rails/LexicallyScopedActionFilter

  respond_to :html

  def show
    show! do
      @aggregate = @aggregate.decorate(context: { workgroup: workgroup })
      @workbench = workgroup.owner_workbench
      @processing = processing
      @aggregate_resources = @aggregate.resources.order(
        params[:sort] || :referential_created_at => params[:direction] || :desc
      )
    end
  end

  def rollback
    resource.rollback!
    redirect_to [:workgroup, :output]
  end

  private

  # Only one processing for aggregate
  def processing
    @aggregate.processings.first
  end

  def build_resource
    super.tap do |aggregate|
      aggregate.creator = current_user.name
      aggregate.referentials = parent.aggregatable_referentials
    end
  end

  def aggregate_params
    aggregate_params = params.require(:aggregate).permit(:referential_ids, :notification_target)
    aggregate_params[:referential_ids] = aggregate_params[:referential_ids].split(",")
    aggregate_params[:user_id] ||= current_user.id
    aggregate_params
  end

  Policy::Authorizer::Controller.for(self, Policy::Authorizer::Legacy)
end
