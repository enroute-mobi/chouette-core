# frozen_string_literal: true

class PublicationSetup < ApplicationModel
  belongs_to :workgroup # CHOUETTE-3247 validates presence
  has_many :publications, dependent: :destroy
  has_many :exports, through: :publications
  has_many :destinations, dependent: :destroy, inverse_of: :publication_setup

  validates :name, presence: true
  validates :priority, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 1000 }
  validates_associated :destinations

  attribute :export_setup, Export::Setup::Base.one_of_descendants.to_type
  validates :export_setup, store_model: true

  accepts_nested_attributes_for :destinations, allow_destroy: true, reject_if: :all_blank

  scope :enabled, -> { where enabled: true }
  scope :export_type, lambda { |export_type|
    where("export_setup->>'type' = ?", EXPORT_TYPE_TO_EXPORT_SETUP_TYPE[export_type])
  }

  EXPORT_SETUP_TYPE_TO_EXPORT_TYPE = {
    'Export::Setup::Gtfs' => 'Export::Gtfs',
    'Export::Setup::Netex' => 'Export::NetexGeneric',
    'Export::Setup::Ara' => 'Export::Ara'
  }.freeze
  EXPORT_TYPE_TO_EXPORT_SETUP_TYPE = EXPORT_SETUP_TYPE_TO_EXPORT_TYPE.invert.freeze

  def assign_attributes(attributes)
    export_type = attributes.delete(:export_type)
    if export_type
      attributes[:export_setup] ||= {}
      attributes[:export_setup][:type] = EXPORT_TYPE_TO_EXPORT_SETUP_TYPE[export_type]
    end
    super(attributes)
  end

  def export_type
    EXPORT_SETUP_TYPE_TO_EXPORT_TYPE[export_setup&.type]
  end

  def self.same_api_usage(other)
   scope = export_type(other.export_type)
   scope = scope.where.not(id: other.id) if other.id
   scope
  end

  def human_export_name
    export_type.constantize.human_name
  end

  def publish(referential, attributes = {})
    publications.create!(attributes.merge(referential: referential))
  end
end
