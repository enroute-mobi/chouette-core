# frozen_string_literal: true

class AggregatesController < Chouette::WorkgroupController
  include PolicyChecker

  defaults resource_class: Aggregate

  respond_to :html

  def show
    @aggregate = @aggregate.decorate(context: { workgroup: workgroup })
    @workbench = workgroup.owner_workbench
    @processing = processing
    @aggregate_resources = @aggregate.resources.order(
      params[:sort] || :referential_created_at => params[:direction] || :desc
    )
  end

  def rollback
    authorize resource
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
end
