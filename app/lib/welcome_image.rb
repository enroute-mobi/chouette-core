class WelcomeImage
  def self.current
    @current = new
  end

  def initialize(collections=[40395285])
    @collections = collections
  end
  attr_accessor :collections

  def image_url
    photo.urls.regular
  end

  def attribution
    photo.user.name
  end

  def photo
    @photo ||= Unsplash::Photo.random(count: 1, collections: collections).first
  end
end