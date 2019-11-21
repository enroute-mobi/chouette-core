class PublicationApi < ActiveRecord::Base
  belongs_to :workgroup
  has_many :api_keys, class_name: 'PublicationApiKey'
  has_many :destinations
  has_many :publication_setups, through: :destinations
  has_many :publication_api_sources

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

  class InvalidAuthenticationError < RuntimeError; end
  class MissingAuthenticationError < RuntimeError; end
end
