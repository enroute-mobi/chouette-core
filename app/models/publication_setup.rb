module PublicationSetupWithDefaultExportOptions
  def export_options
    super || {}
  end
end

class PublicationSetup < ApplicationModel
  prepend PublicationSetupWithDefaultExportOptions

  belongs_to :workgroup
  has_many :publications, dependent: :destroy
  has_many :destinations, dependent: :destroy, inverse_of: :publication_setup

  validates :name, presence: true
  validates :workgroup, presence: true
  validates :export_options, export_options: { extra_attributes: %i[type] }
  validates_associated :destinations

  store_accessor :export_options
  attr_reader :export

  accepts_nested_attributes_for :destinations, allow_destroy: true, reject_if: :all_blank

  scope :enabled, -> { where enabled: true }
  scope :export_type, ->(export_type) { where("export_options -> 'type' = ?", export_type) }

  after_initialize :build_new_export
  before_validation :build_new_export

  def self.same_api_usage(other)
   scope = export_type(other.export_type).
     where(publish_per_line: other.publish_per_line)
   scope = scope.where.not(id: other.id) if other.id
   scope
  end

  def human_export_name
    new_export.human_name
  end

  def export_creator_name
    "#{self.class.ts} #{name}"
  end

  def published_line_ids(referential)
    line_ids = parse_option :line_ids
    company_ids = parse_option :company_ids
    line_provider_ids = parse_option :line_provider_ids

    options = Export::Scope::Options.new(referential, date_range: date_range, line_ids: line_ids, line_provider_ids: line_provider_ids, company_ids: company_ids)

    options.scope.lines.pluck(:id)
  end

  def new_export(extra_options={})
    options = export_options.dup.update(extra_options).symbolize_keys
    export = Export::Base.new(**options) do |export|
      export.creator = export_creator_name
    end

    yield export if block_given?

    export
  end

  def new_exports(referential)
    common_attributes = {
      referential: referential,
      name: "#{self.class.ts} #{name}",
      synchronous: true,
      workgroup: referential.workgroup
    }

    if publish_per_line
      published_line_ids(referential).map do |line_id|
        new_export(line_ids: [line_id], **common_attributes)
      end
    else
      [new_export(common_attributes)]
    end
  end

  def publish(operation, options = {})
    attributes = options.merge(parent: operation)
    publications.create!(attributes)
  end

  def export_type
    export.type
  end

  def build_new_export
    @export = new_export(workgroup: workgroup)
  end

  private

  def date_range
    duration = parse_option :duration
    return nil if duration.nil?
    Time.now.to_date..duration.to_i.days.from_now.to_date
  end

  def parse_option name
    JSON.parse(export_options[name.to_s])
  rescue
    nil
  end
end
