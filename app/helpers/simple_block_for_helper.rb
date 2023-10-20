module SimpleBlockForHelper
  # Generates a block with object attributes
  #
  # == Examples
  #
  #   <%= simple_block_for @object, title: t("...") do |b| %>
  #     <%= b.attribute :started_at, as: :datetime %>
  #   <% end %>
  #
  # == Attribute
  #
  # === Attribute value
  #
  # By default, the attribute value is the value returned by the attribut method
  #
  # value::
  #   The value to replace the attribute value
  # value_method::
  #   The method to be invoked to retrieve the attribute value
  #
  # === Displayed value
  #
  # If present, the attribute value is transformed into a displayed value according to
  # the :as option:
  #
  # datetime::
  #   the value is localized (with short_with_time format)
  # duration::
  #   the value is displayed as "NN min" or "NN sec"
  # enumerize::
  #   the #text method is invoked on the value
  # boolean::
  #   the value is displayed as Yes/No, Oui/Non, etc
  # objectid::
  #   the #short_id method is invoked on the value
  # association::
  #   the #name method is invoked on the value. If the value has an objectid,
  #   its short_id is prefixed
  # associations::
  #   the #name method is invoked on the value. If the value has an Association (has_many),
  #   its short_id is suffix with a link to the object
  # count:
  #   the #count method is invoked on the value. If the count is 0, the value is ignored
  #
  # === Link
  #
  # When the :link option is used, if a value is displayed, a link is build.
  #
  #   d.attribute :parent, as: :association, link: parent_path(@resource.parent)
  #
  # If the link need to create only if a value is displayed, a lambda/Proc can be provided.
  # In this case, the attribute value is provided as argument:
  #
  #   d.attribute :referent, as: :association, link: ->(parent) { referent_path(@parent) }
  #
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
        attribute_method = attribute_name
        if attribute_name == :objectid
          attribute_method = :get_objectid
        end

        raw_value = resource.send(attribute_method)
      end

      label = options[:label] || resource.class.human_attribute_name(attribute_name)
      displayed_value = nil

      if raw_value.present? || raw_value.in?([true, false])
        displayed_value =
          case options[:as]
          when :date
            I18n.l(raw_value, format: :default)
          when :datetime
            I18n.l(raw_value, format: :short_with_time)
          when :time
            I18n.l(raw_value, format: :hour)
          when :time_of_day
            raw_value.to_hm
          when :duration
            raw_value >= 60 ? "#{(raw_value /  1.minute).round} min" : "#{raw_value.round} sec"
          when :enumerize
            raw_value.text
          when :boolean
            t(raw_value)
          when :objectid
            if raw_value.respond_to?(:short_id)
              raw_value.short_id
            else
              raw_value
            end
          when :country
            ISO3166::Country[raw_value]&.translation(I18n.locale) || raw_value
          when :association
            if raw_value.respond_to?(:name)
              [].tap do |parts|
                if raw_value.respond_to?(:get_objectid)
                  parts << raw_value.get_objectid&.short_id
                end
                parts << raw_value.name
              end.compact.join(" ")
            else
              raw_value
            end
          when :associations
            if raw_value.try(:to_a).is_a?(Array) && (link = options[:link]).present?
              content_tag :ul do
                raw_value.collect do |single_raw_value|
                  if link.respond_to?(:call)
                    link_li = link.call(single_raw_value).gsub('.', '/')
                  end

                  displayed_value_li = [single_raw_value.name,  single_raw_value.try(:get_objectid).try(:short_id)].join(' ')
                  concat(content_tag(:li, link_to(displayed_value_li, link_li), class: "step"))
                end
              end
            else
              raw_value
            end
          when :count
            if raw_value.respond_to?(:count)
              raw_value = raw_value.count
            end

            if raw_value > 0
              raw_value
            else
              nil
            end
          when :url
            uri = URI(raw_value)
            uri.user = 'xxx' if uri.user
            uri.password = 'xxx' if uri.password

            if uri.is_a?(URI::HTTP)
              options[:link] ||= raw_value
              uri.to_s.truncate(100)
            else
              uri.to_s
            end
          else
            raw_value
          end

      end

      if displayed_value.present? && (link = options[:link]).present? && options[:as] != :associations
        if link.respond_to?(:call)
          link = link.call(raw_value)
        end
        displayed_value = link_to(displayed_value, link)
      end

      displayed_value ||= "-"

      content_tag(:div, label, class: "dl-term") +
        content_tag(:div, displayed_value, class: "dl-def")
    end
  end
end
