# frozen_string_literal: true

module Chouette
  class ModelPathFinder
    include Rails.application.routes.url_helpers

    attr_accessor :model_class, :model_id, :workbench, :referential

    def initialize(model_class, model_id, workbench, referential = nil)
      @model_class = model_class
      @model_id = model_id
      @workbench = workbench
      @referential = referential
    end

    def path
      if model_class == Chouette::Line
        workbench_line_referential_line_path(workbench, model_id)
      elsif model_class == Chouette::Company
        workbench_line_referential_company_path(workbench, model_id)
      elsif model_class == Chouette::Network
        workbench_line_referential_network_path(workbench, model_id)
      elsif model_class == Chouette::GroupOfLine
        workbench_line_referential_group_of_line_path(workbench, model_id)
      elsif model_class == Chouette::LineNotice
        workbench_line_referential_line_notice_path(workbench, model_id)
      elsif model_class == LineRoutingConstraintZone
        workbench_line_referential_line_routing_constraint_zone_path(workbench, model_id)
      elsif model_class == Chouette::StopArea
        workbench_stop_area_referential_stop_area_path(workbench, model_id)
      elsif model_class == Entrance
        workbench_stop_area_referential_entrance_path(workbench, model_id)
      elsif model_class == ConnectionLink
        workbench_stop_area_referential_connection_link_path(workbench, model_id)
      elsif model_class == StopAreaRoutingConstraint
        workbench_stop_area_referential_stop_area_routing_constraint_path(workbench, model_id)
      elsif model_class == Shape
        workbench_shape_referential_shape_path(workbench, model_id)
      elsif model_class == PointOfInterest::Base
        workbench_shape_referential_point_of_interest_path(workbench, model_id)
      elsif model_class == PointOfInterest::Category
        workbench_shape_referential_point_of_interest_category_path(workbench, model_id)
      elsif model_class == Document
        workbench_document_path(workbench, model_id)
      elsif model_class == Chouette::Route
        redirect_referential_route_path(referential, model_id)
      elsif model_class == Chouette::JourneyPattern
        redirect_referential_journey_pattern_path(referential, model_id)
      elsif model_class == Chouette::VehicleJourney
        redirect_referential_vehicle_journey_path(referential, model_id)
      elsif model_class == Chouette::TimeTable
        referential_time_table_path(referential, model_id)
      else
        Rails.logger.error "Path not found for class #{model_class}"
        nil
      end
    end
  end
end
