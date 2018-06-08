module DevelopmentHelper
  def development_only &block
    return unless Rails.env.development?
    content_tag :span, title: 'this is only shown in dev env', class: 'development-only' do
      capture(&block)
    end
  end
end
