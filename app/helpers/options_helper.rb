# frozen_string_literal: true

module OptionsHelper
  def option_input(form, attr, **options)
    record = form.object
    klass = options[:klass] || record.class
    option_def = klass.options[attr]

    value = record.try(attr).nil? ? option_def[:default_value] : record.try(attr)

    opts = {
      input_html: { value: value },
      as: option_def[:type],
      selected: value
    }

    if option_def[:ajax_collection]
      opts[:as] = :select
      opts[:input_html].merge!({ 'data-domain-name': request.base_url })
      opts[:collection] = []
    elsif option_def[:type] == :boolean
      opts[:as] = :switchable_checkbox
      opts[:input_html][:checked] = value
    elsif option_def[:type] == :array
      opts[:collection] = value.map { |v| { id: v, text: v } }
      opts[:input_html].merge!(
        multiple: true
      )
      opts[:as] = :tom_select
      opts[:config] = {
        type: 'create'
      }

    end

    if option_def.key?(:collection) || option_def.key?(:enumerize)
      if option_def.key?(:enumerize)
        collection = klass.enumerized_attributes[attr].options

        if option_def.key?(:features)
          collection.delete_if do |_, key|
            option_def[:features].key?(key) && !current_organisation.has_feature?(option_def[:features][key])
          end
        end
      else
        collection = record.instance_exec(&option_def[:collection])
      end

      opts[:collection] = collection
      opts[:include_blank] = t('none') if option_def[:allow_blank]
    end

    opts[:label] = klass.human_attribute_name(attr)

    opts[:input_html] = { 'x-on:change': 'import_category = $event.target.value' } if attr == :import_category
    opts[:input_html] = { 'x-on:change': 'host_type = $event.target.value' } if attr == :host_type

    out = form.input attr, opts

    if option_def[:depends]
      out = content_tag :div, 'x-show': "'#{option_def[:depends][:values]}'.includes(import_category)" do
        out
      end.html_safe
    end
    out
  end

  def option_attribute(builder, option_name) # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    record = builder.object
    option_def = record.option_def(option_name)
    val = record.options[option_name.to_s]

    opts = {}
    if option_def[:display] # :collection
      opts[:value_method] = option_def[:display]
      opts[:as] = :association
    elsif option_def[:type] == :boolean
      opts[:value] = t(val.to_s)
    elsif record.class.enumerized_attributes[option_name]
      opts[:value] = record.class.enumerized_attributes[option_name].find_value(val).text
    else
      opts[:value] = val
    end

    builder.attribute option_name, **opts
  end
end
