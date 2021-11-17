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

    # as: :association, link: workbench_stop_area_referential_stop_area_path(@workbench, stop_area)
    def attribute(attribute_name, options = {})
      resource = options[:object] || object

      if options.key?(:value)
        raw_value = options[:value]
      elsif options.key?(:value_method)
        raw_value = resource.send(options[:value_method])
      else
        raw_value = resource.send(attribute_name)
      end

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
            t(raw_value)
          when :objectid
            if resource.respond_to?(:get_objectid)
              resource.get_objectid.short_id
            else
              raw_value
            end
          when :association
            association_displayed_value =
              if raw_value.respond_to?(:name)
                raw_value.name
              else
                raw_value
              end

            if options[:link]
              link_to(association_displayed_value, options[:link])
            else
              association_displayed_value
            end
          else
            raw_value
          end
        else
          '-'
        end

      label = options[:label] || resource.class.human_attribute_name(attribute_name)

      content_tag(:div, label, class: "dl-term") +
        content_tag(:div, displayed_value, class: "dl-def")
    end
  end
end
