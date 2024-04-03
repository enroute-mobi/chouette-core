class GroupedTomSelectInput < SimpleForm::Inputs::GroupedCollectionSelectInput
  delegate :content_tag, :concat, :javascript_additional_packs, to: :template

  def input(_wrapper_options)
    label_method, value_method = detect_collection_methods

    config = options.fetch(:config, {})

    merged_input_options = merge_wrapper_options(
      input_html_options.merge(
        'x-data': '',
        'x-init': "initTomSelect($el, #{config.to_json})"
      ),
      {}
    )

    javascript_additional_packs 'inputs/tom_select'

    @builder.grouped_collection_select(
      attribute_name,
      grouped_collection,
      group_method, group_label_method, value_method, label_method,
      input_options,
      merged_input_options
    )
  end

  private

  def group_method
    @group_method ||= options.delete(:group_method) || :last
  end
end
