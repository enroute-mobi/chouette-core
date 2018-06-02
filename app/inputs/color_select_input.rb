class ColorSelectInput < SimpleForm::Inputs::CollectionInput
  enable :placeholder

  def input(wrapper_options = {})
    selected_color = object.send(attribute_name)
    label = if selected_color
      collection.find{|i| i.is_a?(Enumerable) && i.last == selected_color}.try(:first)
    end

    out = @builder.hidden_field attribute_name, value: selected_color
    tag_name = ActionView::Helpers::Tags::Base.new( ActiveModel::Naming.param_key(object), attribute_name, :dummy ).send(:tag_name)
    font_awesome = attribute_name == :text_color ? 'fa fa-font' : 'fa fa-circle'
    select = <<-eos
  <div class="dropdown color_selector">
    <button type='button' class="btn btn-default dropdown-toggle" data-toggle='dropdown' aria-haspopup='true' aria-expanded='true'
      ><span
        class='#{font_awesome} mr-xs'
        style='color: #{selected_color == nil ? 'transparent' : selected_color}'
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
      select += <<-eos
        <span class="radio" key=#{color} >
          <label>
            <input type='radio' class='color_selector' value='#{color}' data-for='#{tag_name}'/>
            <span class='#{font_awesome} mr-xs' style='color: #{color == nil ? 'transparent' : color}'></span>
            #{name}
          </label>
        </span>
      eos
    end
    select += "</div></div>"

    out + select.html_safe
  end
end
