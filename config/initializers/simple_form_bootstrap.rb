# Use this setup block to configure all options available in SimpleForm.
SimpleForm.setup do |config|
  config.error_notification_class = 'alert alert-danger'
  config.button_class = 'btn btn-default'
  config.boolean_label_class = nil

  config.wrappers :vertical_form, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'control-label'

    b.use :input, class: 'form-control'
    b.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
    b.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
  end

  config.wrappers :vertical_file_input, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :readonly
    b.use :label, class: 'control-label'

    b.use :input
    b.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
    b.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
  end

  config.wrappers :vertical_boolean, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly

    b.wrapper tag: 'div', class: 'checkbox' do |ba|
      ba.use :label_input
    end

    b.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
    b.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
  end

  config.wrappers :vertical_radio_and_checkboxes, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: 'control-label'
    b.use :input
    b.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
    b.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
  end

  config.wrappers :vertical_inline_radio_and_checkboxes, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: 'col-sm-4 col-xs-5 control-label'

    b.wrapper tag: 'div', class: 'col-sm-8 col-xs-7' do |ba|
      ba.use :input
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
    end
  end

  config.wrappers :horizontal_form, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'col-sm-4 col-xs-5 control-label'

    b.wrapper tag: 'div', class: 'col-sm-8 col-xs-7' do |ba|
      ba.use :input, class: 'form-control'
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
    end
  end

  config.wrappers :horizontal_date, tag: 'div', class: 'form-group', error_class: 'has-error', html5: true do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'col-sm-4 col-xs-5 control-label'

    b.wrapper tag: 'div', class: 'col-sm-8 col-xs-7' do |ba|
      ba.use :input, class: 'form-control html5'
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
    end
  end

  config.wrappers :horizontal_file_input, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'col-sm-4 col-xs-5 control-label'

    b.wrapper tag: 'div', class: 'col-sm-8 col-xs-7' do |ba|
      ba.use :input
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
    end
  end

  config.wrappers :horizontal_file_time_select, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :readonly
    b.use :label, class: 'col-sm-8 col-xs-7 control-label'

    b.wrapper tag: 'div', class: 'col-sm-4 col-xs-5' do |ba|
      ba.use :input
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
    end
  end

  config.wrappers :horizontal_boolean, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly

    b.wrapper tag: 'div', class: 'col-sm-offset-3 col-sm-9' do |wr|
      wr.wrapper tag: 'div', class: 'checkbox' do |ba|
        ba.use :label_input
      end

      wr.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
      wr.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
    end
  end

  config.wrappers :horizontal_radio_and_checkboxes, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly

    b.use :label, class: 'col-sm-3 control-label'

    b.wrapper tag: 'div', class: 'col-sm-9' do |ba|
      ba.use :input
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
    end
  end

  config.wrappers :inline_form, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'sr-only'

    b.use :input, class: 'form-control'
    b.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
    b.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
  end

  config.wrappers :multi_select, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: 'control-label'
    b.wrapper tag: 'div', class: 'form-inline' do |ba|
      ba.use :input, class: 'form-control'
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
    end
  end

  config.wrappers :multi_select_inline, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: 'control-label'
    b.wrapper tag: 'div', class: 'form-inline col-sm-8 col-xs-7' do |ba|
      ba.use :input, class: 'form-control'
      ba.use :error, wrap_with: {tag: 'span', class: 'help-block small'}
      ba.use :hint, wrap_with: {tag: 'p', class: 'help-block small'}
    end
  end

  config.wrappers :horizontal_shrinked_select, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :readonly
    b.use :label, class: 'col-sm-8 col-xs-7 control-label'

    b.wrapper tag: 'div', class: 'col-sm-4 col-xs-5' do |ba|
      ba.use :input
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
    end
  end

  config.wrappers :horizontal_shrinked_input, tag: 'div', class: 'form-group', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :readonly
    b.use :label, class: 'col-sm-8 col-xs-7 control-label'

    b.wrapper tag: 'div', class: 'col-sm-4 col-xs-5' do |ba|
      ba.use :input, class: 'form-control'
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
    end
  end

  config.wrappers :horizontal_form_tailwind, tag: 'div', class: 'flex items-center mb-10', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'flex justify-end text-right w-2/6 mr-8 mb-0 control-label pt-0'

    b.wrapper tag: 'div', class: 'w-4/6 flex items-center relative' do |ba|
      ba.use :input, class: 'form-control'
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small absolute top-14 ml-2' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small absolute top-14 ml-2' }
    end
  end

  config.wrappers :vertical_radio_and_checkboxes_tailwind, tag: 'div', class: 'flex items-center mb-10', error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label, class: 'flex justify-end w-2/6 mr-8 mb-0 control-label pt-0'

    b.wrapper tag: 'div', class: 'w-4/6 flex flex-col relative' do |ba|
      ba.use :input, class: 'cursor-pointer'
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small absolute top-14 ml-2' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small absolute top-14 ml-2' }
    end
  end

  config.wrappers :horizontal_boolean_tailwind, tag: 'div', class: '', error_class: 'has-error' do |b|
    b.use :html5
    b.optional :readonly
    b.use :label_input
    b.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
    b.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
  end

  config.wrappers :filters_form_tailwind, tag: 'div', class: 'flex items-center py-3 px-6 border-white', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'control-label pr-6 whitespace-nowrap'

    b.use :input, class: 'shadow appearance-none border border-gray-300 rounded w-full py-4 px-3 bg-white focus:outline-none focus:ring-0 focus:border-blue-500 text-gray-400 leading-7 transition-colors duration-200 ease-in-out'
    b.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
    b.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
  end

  config.wrappers :horizontal_input_editable_select_tailwind, tag: 'div', class: 'flex items-center mb-10', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'flex justify-end w-2/6 mr-8 mb-0 control-label pt-0'

    b.wrapper tag: 'div', class: 'w-4/6 flex items-center relative' do |ba|
      ba.use :input, class: ''
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small absolute top-14 ml-2' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small absolute top-14 ml-2' }
    end
  end

  config.wrappers :nested_fields, tag: 'div', class: 'nested-fields', error_class: 'has-error' do |b|
    b.use :html5
    b.use :placeholder
    b.optional :maxlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly
    b.use :label, class: 'col-sm-4 col-xs-5 control-label'

    b.wrapper tag: 'div', class: 'col-sm-8 col-xs-7' do |ba|
      ba.use :input, class: 'form-control'
      ba.use :error, wrap_with: { tag: 'span', class: 'help-block small' }
      ba.use :hint,  wrap_with: { tag: 'p', class: 'help-block small' }
    end
  end

  # Wrappers for forms and inputs using the Bootstrap toolkit.
  # Check the Bootstrap docs (http://getbootstrap.com)
  # to learn about the different styles for forms and inputs,
  # buttons and other elements.
  config.default_wrapper = :vertical_form
  config.wrapper_mappings = {
    check_boxes: :vertical_radio_and_checkboxes,
    radio_buttons: :vertical_radio_and_checkboxes,
    file: :vertical_file_input,
    boolean: :vertical_boolean,
    datetime: :multi_select,
    date: :multi_select,
    time: :multi_select
  }
end
