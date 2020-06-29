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
    block_tag_with_body(output, options)
  end

  def block_tag_with_body(content, options)
    content_tag :div, class: "definition-list" do
      concat(content_tag(:div, options[:title], class: "dl-head")) if options[:title]
      concat(content_tag(:div, class: "dl-body") do
        content
      end)
    end
  end

  class BlockBuilder < ActionView::Base
    include ActionView::Helpers::TagHelper
    attr_reader :view, :object, :options

    def initialize(view, object, options = {})
      @view = view
      @object = object
      @options = options
    end

    def attribute(attribute_name, options = {})
      raw_value = options.key?(:value) ? options[:value] : object.send(attribute_name)

      displayed_value =
        if raw_value.present? || raw_value.in?([true, false])
          case options[:as]
          when :datetime
            I18n.l(raw_value, format: :short_with_time)
          when :duration
            raw_value > 60 ? "#{(raw_value /  1.minute).round} min" : "#{raw_value.round} sec"
          when :enumerize
            raw_value.text
          when :boolean
            t(raw_value == '1')
          else
            raw_value
          end
        else
          '-'
        end

      content_tag(:div, object.class.human_attribute_name(attribute_name), class: "dl-term") +
        content_tag(:div, displayed_value, class: "dl-def")
    end


  end

end
