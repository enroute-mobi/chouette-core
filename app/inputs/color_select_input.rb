class ColorSelectInput < SimpleForm::Inputs::CollectionInput
  enable :placeholder

  def input(wrapper_options = {})
    selected_color = object.send(attribute_name)
    label = if selected_color
      collection.find{|i| i.is_a?(Enumerable) && i.last == selected_color}.try(:first)
    end
    selected_color_formatted = selected_color.present? ? "##{selected_color}" : nil

    out = @builder.hidden_field attribute_name, value: selected_color
    tag_name = ActionView::Helpers::Tags::Base.new( ActiveModel::Naming.param_key(object), attribute_name, :dummy ).send(:tag_name)
    font_awesome = attribute_name == :text_color ? 'fa fa-font' : 'fa fa-circle'
    select = <<-eos
  <div class="dropdown color_selector">
    <button type='button' class="btn btn-default dropdown-toggle" data-toggle='dropdown' aria-haspopup='true' aria-expanded='true'
      ><span
        class='#{font_awesome} mr-xs'
        style='color: #{selected_color_formatted == nil ? 'transparent' : selected_color_formatted}'
        >
      </span>
      #{label}
      <span class='caret'></span>
    </button>

    <div class="form-group dropdown-menu" aria-labelledby='dpdwn_color'>
    eos

    collection.each do |color|
      name = nil
      name, color = color if color.is_a?(Enumerable)
      full_color = "##{color}"
      select += <<-eos
        <span class="radio" key=#{full_color} >
          <label>
            <input type='radio' class='color_selector' value='#{color}' data-for='#{tag_name}'/>
            <span class='#{font_awesome} mr-xs' style='color: #{color == nil ? 'transparent' : full_color}'></span>
            #{name}
          </label>
        </span>
      eos
    end
    select += "</div></div>"

    out + select.html_safe
  end
end
