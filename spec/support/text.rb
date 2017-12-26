require 'htmlbeautifier'

module Support::Text

  def beautify_html html, indent: 4
    HtmlBeautifier.beautify(html, indent: ' ' * indent)
  end

  def colorized_diff(actual, expected)
    RSpec::Support::Differ.new(
      color: RSpec::Matchers.configuration.color?
    ).diff_as_string(expected, actual)
  end
end

RSpec.configure do | config |
  config.include Support::Text
end
