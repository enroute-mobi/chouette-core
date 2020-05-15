module SimpleBlockForHelper
  # Generates a block.
  # Usage:
  #   <%= simple_block_for @object do |b| %>
  #     <%= b.title :processing %>
  #     <%= b.attribute :started_at %>
  #   <% end %>
  def simple_block_for(object, options = {}, &block)
    block_builder = BlockBuilder.new(self, object, options)
    output = capture(block_builder, &block)
    options[:class] = "col-lg-12 col-md-12 col-sm-12 col-xs-12" unless options[:class]
    block_tag_with_body(output, options)
  end

  def block_tag_with_body(content, options)
    content_tag :div, class: options[:class] do
      content_tag :div, class: "definition-list" do
        concat(content_tag(:div, options[:title], class: "dl-head")) if options[:title]
        concat(content_tag(:div, class: "dl-body") do
          content
        end)
      end
    end
  end

  class BlockBuilder < ActionView::Base
    include  ActionView::Helpers::TagHelper
    attr_reader :view, :object, :options

    def initialize(view, object, options = {})
      @view = view
      @object = object
      @options = options
    end

    def attribute(attribute_name, options = {})
      output = content_tag(:div, object.class.human_attribute_name(attribute_name), class: "dl-term")

      attribute_type = options[:as]
      attribute_value = options[:value]

      attribute_value_unformatted = attribute_value || object.send(attribute_name)

      attribute_value_formatted = "-"
      if attribute_value_unformatted.present?
        case attribute_type
          when :datetime
            attribute_value_formatted = I18n.l(attribute_value_unformatted, format: :short_with_time)
          when :duration
            attribute_value_formatted = attribute_value_unformatted > 60 ? "#{(attribute_value_unformatted /  1.minute).round} min" : "#{attribute_value_unformatted.round} sec"
          when :enumerize
            attribute_value_formatted = attribute_value_unformatted.text
          else
            attribute_value_formatted = attribute_value_unformatted
        end
      end

      output << content_tag(:div, attribute_value_formatted, class: "dl-def")
    end


  end

end
