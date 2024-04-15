class ReferentialDecorator < AF83::Decorator
  decorates Referential

  set_scope { context[:workbench] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.action_link secondary: :show, on: :show, policy: :browse do |l|
      l.content t('accessibility_assessments.index.title')
      l.href { h.workbench_referential_accessibility_assessments_path(context[:workbench], object) }
    end

    instance_decorator.action_link secondary: :show, on: :show, policy: :browse do |l|
      l.content t('referential_vehicle_journeys.index.title')
      l.href { h.workbench_referential_vehicle_journeys_path(context[:workbench], object) }
    end

    instance_decorator.action_link secondary: :show, policy: :browse do |l|
      l.content t('time_tables.index.title')
      l.href { h.workbench_referential_time_tables_path(context[:workbench], object) }
    end

    instance_decorator.action_link policy: :clone, secondary: :show do |l|
      l.content t('actions.clone')
      l.href { h.new_workbench_referential_path(context[:workbench], from: object.id) }
    end

    instance_decorator.action_link policy: :validate, secondary: :show, if: ->{ object.workbench } do |l|
      l.content t('actions.validate')
      l.href { h.new_workbench_control_list_run_path(context[:workbench], referential_id: object.id) }
    end

    instance_decorator.action_link policy: :archive, secondary: :show do |l|
      l.content t('actions.archive')
      l.href { h.archive_workbench_referential_path(context[:workbench], object.id) }
      l.method :put
    end

    instance_decorator.action_link policy: :unarchive, secondary: :show do |l|
      l.content t('actions.unarchive')
      l.href { h.unarchive_workbench_referential_path(context[:workbench], object.id) }
      l.method :put
    end

    instance_decorator.action_link policy: :edit, secondary: :show, on: :show do |l|
      l.content t('actions.clean_up')
      l.href { h.new_workbench_referential_clean_up_path(context[:workbench], object.id) }
    end

    instance_decorator.crud
  end
end
