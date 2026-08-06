# frozen_string_literal: true

require 'nest/helpers/simple_block_for/builder'

module Chouette
  module SimpleBlockFor
    class Builder < Nest::Helpers::SimpleBlockFor::Builder
      class BooleanIconFormat < Nest::Helpers::SimpleBlockFor::Builder::BooleanFormat
        def displayed_value
          view.boolean_icon(raw_value)
        end
      end

      class TimeOfDayFormat < Nest::Helpers::SimpleBlockFor::Builder::Format
        def displayed_value
          raw_value.to_hm
        end
      end

      class CountryFormat < Nest::Helpers::SimpleBlockFor::Builder::Format
        def displayed_value
          ISO3166::Country[raw_value]&.translation(I18n.locale) || raw_value
        end
      end

      class AssociationFormat < Nest::Helpers::SimpleBlockFor::Builder::AssociationFormat
        def displayed_value
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
        end
      end

      class AssociationsFormat < Nest::Helpers::SimpleBlockFor::Builder::AssociationsFormat
        protected

        def render_list_item(single_displayed_value)
          content_tag(:li, single_displayed_value, class: 'step')
        end
      end

      class TagsFormat < Nest::Helpers::SimpleBlockFor::Builder::Format
        def displayed_value
          content_tag :div, class: 'flex flex-wrap' do
            raw_value.map do |tag|
              url = view.workbench_tag_path(view.current_workbench, tag)

              content_tag(
                :div,
                link_to(tag.name, url, style: 'color: black;'),
                style: "background-color: ##{tag.color};",
                class: 'inline-flex items-center px-2.5 py-0.5 mr-2 rounded-full text-sm font-medium'
              )
            end.join.html_safe # rubocop:disable Rails/OutputSafety
          end
        end
      end

      class DaysFormat < Nest::Helpers::SimpleBlockFor::Builder::Format
        def displayed_value
          content_tag(:div) do
            Cuckoo::DaysOfWeek.days.map do |day|
              content_tag(
                :span,
                I18n.t("calendars.days.#{day}"),
                class: "label label-default #{raw_value.send("#{day}?") ? '' : 'disabled'}"
              )
            end.join.html_safe
          end
        end
      end

      def render_definition_list(content)
        view.content_tag(:div, class: 'definition-list') do
          view.concat(view.content_tag(:div, options[:title], class: 'dl-head')) if options[:title]
          view.concat(view.content_tag(:div, class: 'dl-body') { content })
        end
      end

      def render_attribute(label, displayed_value)
        label_div(label) + displayed_value_div(displayed_value)
      end

      protected

      def label_div(label)
        content_tag(:div, label, class: 'dl-term')
      end

      def displayed_value_div(displayed_value)
        content_tag(:div, displayed_value, class: 'dl-def')
      end
    end
  end
end
