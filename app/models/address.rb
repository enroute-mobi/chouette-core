class Address
  attr_accessor :house_number, :street_name, :post_code, :city_name, :country_code

  def initialize(house_number=nil, street_name=nil, post_code=nil, city_name=nil, country_code=nil)
    @house_number = house_number
    @street_name = street_name
    @post_code = post_code
    @city_name = city_name
    @country_code = country_code
  end

  def country
    return unless country_code
    ISO3166::Country[country_code]
  end

  def country_name
    return unless country
    country.translations[I18n.locale.to_s] || country.name
  end

  alias postal_code post_code
end