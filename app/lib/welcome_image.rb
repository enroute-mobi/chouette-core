class WelcomeImage
  def self.current
    @current = new([40395285])
  end

  def initialize(collections)
    @collections = collections
  end
  attr_accessor :collections

  DEFAULT_IMAGE_URL = 'default.png'

  def image_url
    return DEFAULT_IMAGE_URL unless photo

    photo.urls.regular
  end

  def name
    return unless photo

    photo.user.name
  end

  def username
    return unless photo

    photo.user.username
  end

  def photo
    return if Rails.env.test? || ENV['UNSPLASH_ACCESS_KEY'].blank?

    @photo ||= Unsplash::Photo.random(count: 1, collections: collections).first
  end
end