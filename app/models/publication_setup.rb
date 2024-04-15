module PublicationSetupWithDefaultExportOptions
  def export_options
    super || {}
  end
end

class PublicationSetup < ApplicationModel
  prepend PublicationSetupWithDefaultExportOptions

  belongs_to :workgroup
  has_many :publications, dependent: :destroy
  has_many :exports, through: :publications
  has_many :destinations, dependent: :destroy, inverse_of: :publication_setup

  validates :name, presence: true
  validates :workgroup, presence: true
  validates_associated :destinations

  store_accessor :export_options

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

  def publish(operation, options = {})
    attributes = options.merge(creator: operation.creator, parent: operation)
    publications.create!(attributes)
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
