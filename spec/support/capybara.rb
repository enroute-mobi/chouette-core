# frozen_string_literal: true

Capybara.asset_host = 'http://localhost:3001'

Capybara.add_selector(:hidden_field) do
  visible :hidden
  xpath do |locator|
    xpath = XPath.descendant(:input)[XPath.attr(:type) == 'hidden']
    xpath = xpath[(XPath.attr(:id) == locator) | (XPath.attr(:name) == locator)] if locator
    xpath
  end
  filter(:with) do |node, with|
    with.all? { |k, v| node.respond_to?(k) && node.send(k) == v }
  end
end
