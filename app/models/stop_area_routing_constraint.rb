class StopAreaRoutingConstraint < ApplicationModel
  include StopAreaReferentialSupport
  include ChecksumSupport

  belongs_to :from, class_name: 'Chouette::StopArea'
  belongs_to :to, class_name: 'Chouette::StopArea'

  add_light_belongs_to :from
  add_light_belongs_to :to

  validates :from, presence: true
  validates :to, presence: true

  validate :both_stops_in_the_same_referential
  validate :different_stops

  scope :with_stop, ->(stop_id){
    stop_id = stop_id.id if stop_id.respond_to?(:id)
    where('from_id = :stop_id OR to_id = :stop_id', stop_id: stop_id)
  }

  def self.ransackable_scopes(auth_object = nil)
    %i[with_stop]
  end

  def both_stops_in_the_same_referential
    if from and stop_area_referential_id != from.stop_area_referential_id
      errors.add(:from_id, :must_be_in_same_referential)
    end

    if to and stop_area_referential_id != to.stop_area_referential_id
      errors.add(:to_id, :must_be_in_same_referential)
    end
  end

  def different_stops
    return unless from && to
    return if from != to

    errors.add(:to_id, :must_be_a_different_stop)
  end

  def name
    separator = both_way? ? '<>' : '>'
    "#{from_light.name} #{separator} #{to_light.name}"
  end

  def checksum_attributes(db_lookup = true)
    [
      [from_id, to_id, both_way]
    ]
  end

  def referentials
    Referential.where(stop_area_referential_id: stop_area_referential.id)
  end
end
