# frozen_string_literal: true

module IntegrationSpecHelper
  extend ActiveSupport::Concern

  class_methods do
    def with_permission(permission, &block)
      context "with permission #{permission}" do
        let(:permissions) { [permission] }
        context('', &block) if block_given?
      end
    end

    def with_feature(feature, &block)
      context "with feature #{feature}" do
        let(:features) { [feature] }
        context('', &block) if block_given?
      end
    end
  end

  def paginate_collection(klass, decorator, page = 1, context = {})
    collection = klass.page(page)
    if decorator
      collection = if decorator < AF83::Decorator
                     decorator.decorate(collection, context: context)
                   else
                     ModelDecorator.decorate(collection, with: decorator, context: context)
                   end
    end
    collection
  end

  def build_paginated_collection(factory, decorator, opts = {})
    context = opts.delete(:context) || {}
    count = opts.delete(:count) || 2
    page = opts.delete(:page) || 1
    klass = nil
    count.times { klass = create(factory, opts).class }
    paginate_collection klass, decorator, page, context
  end
end

RSpec.configure do |config|
  config.include IntegrationSpecHelper, type: :view
end

RSpec::Matchers.define :have_menu_title do |title|
  match do
    expect(rendered).to have_selector("#menu-items .panel-heading h4", text: title)
  end
  description { "have '#{title}' menu title" }
  failure_message do
    "Did not find a menu block with title '#{title}'"
  end
end

RSpec::Matchers.define :have_menu_link_to do |url|
  match do
    expect(rendered).to have_selector("#menu-items a[href='#{url}']")
  end
  description { "have a menu link pointing to '#{url}'" }
  failure_message do
    "Did not find a menu link pointing to '#{url}'"
  end
end

RSpec::Matchers.define :have_link_for_each_item do |collection, name, opts|
  opts = {href: opts} unless opts.is_a? Hash
  href = opts[:href]
  method = opts[:method]
  method_selector = method.present? ? "[data-method='#{method.downcase}']": ""
  match do |actual|
    collection.each do |item|
      @selector = "tr.#{TableBuilderHelper.item_row_class_name(collection)}-#{item.id} .actions a[href='#{href.call(item)}']#{method_selector}"
      expect(rendered).to have_selector(@selector, count: 1)
    end
  end
  description { "have #{name} link for each item" }
  failure_message do
    "expected view to have one #{name} link for each item, failed with selector: \"#{@selector}\""
  end
end

RSpec::Matchers.define :have_the_right_number_of_links do |collection, count|
  match do
    collection.each do |item|
      @selector = "tr.#{TableBuilderHelper.item_row_class_name(collection)}-#{item.id} .actions a"
      expect(rendered).to have_selector(@selector, count: count)
    end
  end
  description { "have #{count} links for each item" }
  failure_message do
    actual = Capybara::Node::Simple.new(rendered).all(@selector).count
    "expected #{count} links for each item, got #{actual} for \"#{@selector}\""
  end
end
