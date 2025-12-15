# frozen_string_literal: true

require 'nest/helpers/search/form_builder'

module Chouette
  module Search
    class FormBuilder < Nest::Helpers::Search::FormBuilder
      class << self
        def layout
          'searches/form'
        end
      end

      def name(**options)
        generic_text(:name, **options)
      end

      def input(attribute, **options)
        options[:input_html] ||= { "@keydown.enter.prevent": "document.getElementById('filter').click();" }
        super(attribute, **options)
      end

      def row(&block)
        template.content_tag(:div, class: 'flex items-center border-t border-white h-14', &block)
      end

      protected

      def generic_text(name, **options)
        super(name, width: 2, placeholder: nil, **options)
      end

      def width_class(width)
        "w-#{width}/5"
      end

      def default_wrapper_html_class
        'border-l'
      end

      def default_input_html_class
        nil
      end

      def default_label_html_class
        nil
      end

      private

      def add_label_in_input_options(options, _attribute)
        options[:label] = false if options[:as] == :hidden
      end
    end
  end
end
