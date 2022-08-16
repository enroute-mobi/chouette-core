class PublicationApi < ActiveRecord::Base
  belongs_to :workgroup
  has_many :api_keys, class_name: 'PublicationApiKey'
  has_many :destinations
  has_many :publication_setups, through: :destinations
  has_many :publication_api_sources, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  # When updating this regex, please update the
  # corresponding one in app/javascript/packs/publication_apis/new.js
  validates_format_of :slug, with: %r{\A[0-9a-zA-Z_]+\Z}

  def public_url
    "#{SmartEnv['PUBLIC_HOST']}/api/v1/datas/#{slug}"
  end

  def public?
    !!public
  end

  def authenticate(token)
    public? || api_keys.where(token: token).exists?
  end

  def last_publication_at
    # It appears that publication_api_sources.maximum(:updated_at) returns a different class, that lost the UTC +x information, so we opted for another method
    publication_api_sources.order(updated_at: :desc).first&.updated_at
  end

  class InvalidAuthenticationError < RuntimeError; end
  class MissingAuthenticationError < RuntimeError; end
end
