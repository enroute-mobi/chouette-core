if Rails.application.config.try(:reflex_api_url)
  ICar::API.base_url = Rails.application.config.reflex_api_url
end
