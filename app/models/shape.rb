# frozen_string_literal: true

class Shape < ApplicationModel
  include ShapeReferentialSupport
  include CodeSupport

  has_many :waypoints, -> { order(:position) }, inverse_of: :shape, dependent: :delete_all

  delegate :workbench, :to => :shape_provider, :allow_nil => true

  validates :geometry, presence: true

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
end
