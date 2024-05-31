# frozen_string_literal: true

module OptionsHelper
  def option_input(form, export, attr, option_def, type)
    attr = option_def[:name] if option_def[:name].present?

    value = export.try(attr).nil? ? option_def[:default_value] : export.try(attr)

    opts = {
      input_html: { value: value },
      as: option_def[:type],
      selected: value
    }

    if option_def[:hidden]
      opts[:as] = :hidden
    elsif option_def[:ajax_collection]
      opts[:as] = :select
      opts[:input_html].merge!({ 'data-domain-name': request.base_url })
      opts[:collection] = []
    elsif option_def[:type].to_s == 'boolean'
      opts[:as] = :switchable_checkbox
      opts[:input_html][:checked] = value
    elsif option_def[:type].to_s == 'array'
      opts[:collection] = value.map { |v| { id: v, text: v } }
      opts[:input_html].merge!(
        multiple: true
      )
      opts[:as] = :tom_select
      opts[:config] = {
        type: 'create',
        placeholder: I18n.t('simple_form.custom_inputs.tags.placeholder')
      }

    end

    if option_def.key?(:collection)
      opts[:collection] = if option_def[:collection].is_a?(Array) && !option_def[:collection].first.is_a?(Array)
                            option_def[:collection].map { |k| [translate_option_value(type, attr, k), k] }
                          else
                            option_def[:collection]
                          end
      opts[:collection] = export.instance_exec(&option_def[:collection]) if option_def[:collection].is_a?(Proc)

      if option_def[:allow_blank]
        if opts[:collection].respond_to? :model
          none = opts[:collection].model.new
          opts[:collection] = [none] + opts[:collection].sort_by(&:name)
        else
          opts[:collection] = opts[:collection].push([t('none'), nil])
        end
      end
    end
    opts[:label] = translate_option_key(type, attr)

    opts[:input_html] = { 'x-on:change': 'import_category = $event.target.value' } if attr == :import_category

    out = form.input attr, opts

    if option_def[:depends]
      klass = 'hidden' if option_def[:hidden]
      out = content_tag :div, class: klass, 'x-show': "'#{option_def[:depends][:values]}'.includes(import_category)" do
        out
      end.html_safe
    end
    out
  end

  def display_option_value(record, option_name)
    option = record.option_def(option_name)
    val = record.options[option_name.to_s]

    if option[:display]
      instance_exec(val, &option[:display])
    elsif option[:type] == :boolean
      val.to_s.t
    elsif option.key?(:collection)
      translate_option_value(record.object.class, option_name, val)
    else
      val
    end
  end

  def translate_option_key(parent_class, key)
    root = parent_class
    root = Destination if root < Destination
    root.tmf("#{parent_class.name.demodulize.underscore}.#{key}")
  end

  def translate_option_value(parent_class, attr, key)
    root = parent_class
    root = Destination if root < Destination
    root.tmf("#{parent_class.name.demodulize.underscore}.#{attr}_collection.#{key}", default: key)
  end
end
