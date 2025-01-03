class PublicationApiKey < ActiveRecord::Base

  validates :name, presence: true

  belongs_to :publication_api # TODO: CHOUETTE-3247 optional: true?

  before_save :generate_token

  private

  def generate_token
    return if token.present?
    self.token = loop do
      random_token = SecureRandom.urlsafe_base64(nil, false)
      break random_token unless PublicationApiKey.exists?(token: random_token)
    end
  end
end
