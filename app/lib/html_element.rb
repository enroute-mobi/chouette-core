class HtmlElement
  attr_reader :content, :options, :tag_name

  def initialize(tag_name, content = nil, options = nil)
    @tag_name = tag_name
    @content = content
    @options = options
  end

  def to_html(options = {})
    ApplicationController.helpers.content_tag(
      @tag_name,
      @content,
      @options.merge(options)
    )
  end
end
