# frozen_string_literal: true

# Add support for :item_input_html option, to customize each item radio_button:
#   f.input :attribute, as: :radio_buttons, item_input_html: { "x-model" => "attribute" }
class CollectionRadioButtonsInput < SimpleForm::Inputs::CollectionRadioButtonsInput
  def build_nested_boolean_style_item_tag(collection_builder)
    item_input_html = options.fetch(:item_input_html, {})
    collection_builder.radio_button(item_input_html) + collection_builder.text.to_s
  end
end
