class ReferentialDecorator < AF83::Decorator
  decorates Referential

  with_instance_decorator do |instance_decorator|
    instance_decorator.show_action_link
    instance_decorator.edit_action_link

    instance_decorator.action_link feature: :referential_vehicle_journeys, secondary: :show, on: :show do |l|
      l.content t('referential_vehicle_journeys.index.title')
      l.href { h.referential_vehicle_journeys_path(object) }
    end

    instance_decorator.action_link feature: :purchase_windows, secondary: :show, on: :show do |l|
      l.content t('purchase_windows.index.title')
      l.href { h.referential_purchase_windows_path(object) }
    end

    instance_decorator.action_link secondary: :show do |l|
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

    instance_decorator.action_link policy: :unarchive, secondary: :show, on: :show do |l|
      l.content t('actions.unarchive')
      l.href { h.unarchive_referential_path(object.id) }
      l.method :put
    end

    instance_decorator.action_link policy: :edit, secondary: :show, on: :show do |l|
      l.content t('actions.clean_up')
      l.href '#'
      l.type 'button'
      l.data {{
        toggle: 'modal',
        target: '#purgeModal'
      }}
    end

    instance_decorator.destroy_action_link  do |l|
      l.href { h.referential_path(object) }
      l.data {{ confirm: h.t('referentials.actions.destroy_confirm') }}
    end
  end
end
