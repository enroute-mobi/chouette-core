class ImportDecorator < AF83::Decorator
  decorates Import::Base

  set_scope { context[:parent] }

  define_instance_method :import_status_css_class do
    cls =''
    cls = 'overheaded-success' if object.status == 'successful'
    cls = 'overheaded-warning' if object.status == 'warning'
    cls = 'overheaded-danger' if %w[failed aborted canceled].include? object.status
    cls
  end

  define_instance_method :i18n_attribute_scope do
    [:activerecord, :attributes, :import, short_type.to_sym]
  end

  define_instance_method :referential_link do
    if object.referential.present?
      link_to_if_i_can(object.referential.name, object.referential)
    elsif object.is_a?(Import::Shapefile) || (object.is_a?(Import::Resource) && object.root_import&.import_category == "shape_file") || (object.is_a?(Import::Workbench) && object&.import_category == "shape_file")
      link_to(ShapeReferential.t.capitalize, workbench_shape_referential_shapes_path(object.workbench))
    end
  end

  create_action_link if: -> { context[:parent].is_a? (Workbench) }

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link

    instance_decorator.action_link secondary: :show do |l|
      l.content  t('imports.actions.download')
      l.icon     :download
      l.href     { h.download_workbench_import_path object.workbench, object }
      l.disabled { !object.file.present? }
      l.download { h.download_workbench_import_path object.workbench, object }
    end
  end
end
