# frozen_string_literal: true

class AutocompleteController < Chouette::UserController
  include WithinWorkgroup

  ##############
  # Line scope #
  ##############
  def lines
    @lines = line_scope.lines.order(:name).by_text(text).limit(50)
  end

  def line_notices
    @line_notices = line_scope.line_notices.order(:title).by_text(text).limit(50)
  end

  def companies
    @companies = line_scope.companies.order(:name).by_text(text).limit(50)
  end

  def line_providers
    @line_providers = line_scope.line_providers.order(:short_name).by_text(text).limit(50)
  end

  def shapes
    @shapes ||= shape_referential.shapes.by_text(text).limit(50)
  end

  def users
    @users ||= current_organisation.users.by_text(text).limit(50)
  end

  def macro_lists
    @macro_lists ||= workbench.macro_lists.by_text(text).limit(50)
  end

  def control_lists
    @control_lists ||= workbench.control_lists.by_text(text).limit(50)
  end

  def calendars
    @calendars ||= workbench.calendars_with_shared.by_text(text).limit(50)
  end

  ##################
  # StopArea scope #
  ##################

  def stop_areas
    return Chouette::StopArea.none if text.blank?
    @stop_areas = stop_area_scope.stop_areas.by_text(text).limit(50)
  end

  def parent_stop_areas
    return Chouette::StopArea.none if text.blank?
    @stop_areas = stop_area_scope.stop_areas.parent_stop_areas.by_text(text).limit(50)
  end

  def stop_area_providers
    @stop_area_providers = stop_area_scope.stop_area_providers.order(:name).by_text(text).limit(50)
  end

  protected

  def text
    @text = params[:q]&.strip
  end

  def stop_area_scope
    stop_area_referential || workbench || referential
  end

  def line_scope
    line_referential || workbench || referential
  end

  def stop_area_referential
    @stop_area_referential ||= current_workgroup&.stop_area_referential
  end

  def line_referential
    @line_referential ||= current_workgroup&.line_referential
  end

  def shape_referential
    @shape_referential ||= current_workgroup&.shape_referential
  end

  def current_workgroup
    current_user.workgroups.find(params[:workgroup_id]) if params[:workgroup_id]
    @current_workgroup ||= workbench&.workgroup
  end

  def workbench
    @workbench ||= current_user.workbenches.find(params[:workbench_id]) if params[:workbench_id]
  end

  def referential
    @referential ||= workbench.find_referential!(params[:referential_id]) if params[:referential_id]
  end
end
