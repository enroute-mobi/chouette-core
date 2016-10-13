if Rails.application.config.try(:codifligne_api_url)
  Codifligne::API.base_url = Rails.application.config.codifligne_api_url
end
