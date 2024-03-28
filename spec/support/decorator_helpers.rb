# frozen_string_literal: true

module Support
  module DecoratorHelpers
    extend ActiveSupport::Concern

    included do
      let(:context) { {} }

      subject(:decorator) { object.decorate(context: context) }
    end

    def expect_action_link_hrefs(action = :index)
      if decorator.action_links.is_a? AF83::Decorator::ActionLinks
        expect(decorator.action_links(action).map(&:href))
      else
        expect(decorator.action_links.select(&Link.method(:===)).map(&:href))
      end
    end

    def expect_action_link_elements(action = :index) # rubocop:disable Metrics/AbcSize
      if decorator.action_links.is_a? AF83::Decorator::ActionLinks
        expect(decorator.action_links(action).map do |l|
          l.content.gsub(%r{<span.*/span>}, '')
        end)
      else
        expect(decorator.action_links.select(&HTMLElement.method(:===)).map do |l|
          l.content.gsub(%r{<span.*/span>}, '')
        end)
      end
    end
  end
end

RSpec.configure do |config|
  config.include Support::DecoratorHelpers, type: :decorator
end
