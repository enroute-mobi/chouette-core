class ApiKey < ApplicationModel
  has_metadata

  before_validation :generate_access_token, on: :create

  belongs_to :workbench # CHOUETTE-3247 validates presence

  validates :token, presence: true, uniqueness: true

  def eql?(other)
    return false unless other.respond_to?(:token)
    other.token == token
  end

  def workgroup
    workbench&.workgroup
  end

  private

  def generate_access_token
    return if token.present?

    loop do
      self.token = SecureRandom.hex
      break token unless self.class.where(token: token).exists?
    end
  end
end
