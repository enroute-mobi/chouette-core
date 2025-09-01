# frozen_string_literal: true

module PublicationSetupWithDefaultExportOptions
  def export_options
    super || {}
  end
end

class PublicationSetup < ApplicationModel
  prepend PublicationSetupWithDefaultExportOptions

  belongs_to :workgroup # CHOUETTE-3247 validates presence
  has_many :publications, dependent: :destroy
  has_many :exports, through: :publications
  has_many :destinations, dependent: :destroy, inverse_of: :publication_setup

  validates :name, presence: true
  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }
  validates_associated :destinations

  store_accessor :export_options

  attribute :export_setup, Export::Setup::Base.one_of_descendants.to_type

  def migrate_export_options_to_export_setup
    load Rails.root.join('db/migrate/20250822093323_add_export_setup_to_exports_and_publications.rb')
    migration = AddExportSetupToExportsAndPublications.new
    self.export_setup = migration.send(:migrate_publication_setup_export_options_to_export_setup, export_options.deep_stringify_keys)
  end
  before_save :migrate_export_options_to_export_setup

  accepts_nested_attributes_for :destinations, allow_destroy: true, reject_if: :all_blank

  scope :enabled, -> { where enabled: true }
  scope :export_type, ->(export_type) { where("export_options -> 'type' = ?", export_type) }

  def self.same_api_usage(other)
   scope = export_type(other.export_type)
   scope = scope.where.not(id: other.id) if other.id
   scope
  end

  def human_export_name
    export_type.constantize.human_name
  end

  # export_options requires JSON parsing .. because hstore :-/
  def export_scope_options
    {
      line_ids: parse_option(:line_ids),
      company_ids: parse_option(:company_ids),
      line_provider_ids: parse_option(:line_provider_ids)
    }
  end

  def publish(referential, attributes = {})
    publications.create!(attributes.merge(referential: referential))
  end

  def export_type
    export_options["type"]
  end


  # DEPRECATED FIXME etc ...
  # We should not create a Building to check its Address
  validates :export_options, export_options: { extra_attributes: %i[type] }
  def export
    Export::Base.new(export_options.merge(workgroup: workgroup))
  end

  private

  def parse_option name
    JSON.parse(export_options[name.to_s])
  rescue
    nil
  end
end
