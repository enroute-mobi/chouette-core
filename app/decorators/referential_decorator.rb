class ReferentialDecorator < AF83::Decorator
  decorates Referential

  with_instance_decorator do |instance_decorator|
    instance_decorator.action_link secondary: :show, on: :show, policy: :browse do |l|
      l.content t('referential_vehicle_journeys.index.title')
      l.href { h.referential_vehicle_journeys_path(object) }
    end

    instance_decorator.action_link secondary: :show, policy: :browse do |l|
      l.content t('time_tables.index.title')
      l.href { h.referential_time_tables_path(object) }
    end

    instance_decorator.action_link policy: :clone, secondary: :show do |l|
      l.content t('actions.clone')
      l.href { h.duplicate_workbench_referential_path(object) }
    end

    instance_decorator.action_link policy: :validate, secondary: :show do |l|
      l.content t('actions.validate')
      l.href { h.select_compliance_control_set_referential_path(object.id) }
    end

    instance_decorator.action_link policy: :archive, secondary: :show do |l|
      l.content t('actions.archive')
      l.href { h.archive_referential_path(object.id) }
      l.method :put
    end

    instance_decorator.action_link policy: :unarchive, secondary: :show do |l|
      l.content t('actions.unarchive')
      l.href { h.unarchive_referential_path(object.id) }
      l.method :put
    end

    instance_decorator.action_link policy: :edit, secondary: :show, on: :show do |l|
      l.content t('actions.clean_up')
      l.href { h.new_referential_clean_up_path(object.id) }
    end

    instance_decorator.crud
  end
end
