class Shape < ApplicationModel

  belongs_to :shape_referential, required: true
  belongs_to :shape_provider, required: true
  has_many :waypoints, dependent: :delete_all

  delegate :workbench, :to => :shape_provider, :allow_nil => true

  has_many :codes, as: :resource, dependent: :delete_all

  validates :geometry, presence: true
  # TODO May be usefull, but must not impact performance
  # validates :shape_provider, inclusion: { in: ->(shape) { shape.shape_referential.shape_providers } }, if: :shape_referential

  before_validation :define_shape_referential, on: :create

  scope :by_code, ->(code_space, value) {
    joins(:codes).where(codes: { code_space: code_space, value: value })
  }

  scope :by_text, -> (text) { text.blank? ? all : where('unaccent(shapes.name) ILIKE :t OR shapes.uuid::varchar LIKE :t', t: "%#{text.downcase}%") }

  def associations
    CrossReferentialIndexEntry.where(relation_name: :shape, parent_id: id)
  end

  def human_attribute_name(*args)
    self.class.human_attribute_name(*args)
  end

  def length
    @length ||= calculate_length
  end

  def calculate_length
    # TODO fix this sql query => needs postgis knowledge
    # query =  "select st_length(geom::geography)/1000 from st_geomfromtext('LINESTRING(12 50, 13 51)', 4326) as geom"
    # ActiveRecord::Base.connection.execute(query).first
    1
  end

  private

  # Allow ransack to query using "LIKE" on uuids
  ransacker :uuid do
    Arel.sql("#{table_name}.uuid::varchar")
  end

  def define_shape_referential
    # TODO Improve performance ?
    self.shape_referential ||= shape_provider&.shape_referential
  end

end
