# -*- coding: utf-8 -*-
module ImportsHelper

  def bootstrap_class_for_message_criticity(message_criticity)
    case message_criticity.downcase
    when 'error', 'aborted'
      'alert alert-danger'
    when 'warning'
      'alert alert-warning'
    when 'info'
      'alert alert-info'
    when 'ok', 'success'
      'alert alert-success'
    else
      message_criticity.to_s
    end
  end

  def import_message_content(message)
    export_message_content message
  end

  def referential_link(import)
    if import.referential.present?
      link_to_if_i_can(import.referential.name, import.referential)
    elsif import.is_a?(Import::Shapefile) || (import.is_a?(Import::Resource) && import.root_import.try(:import_category)=="shape_file") ||(import.is_a?(Import::Workbench) && import.try(:import_category)=="shape_file")
      link_to(ShapeReferential.t.capitalize, workbench_shape_referential_shapes_path(import.workbench))
    end
  end
end
