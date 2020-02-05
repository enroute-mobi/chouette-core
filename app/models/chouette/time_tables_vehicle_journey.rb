class Chouette::TimeTablesVehicleJourney < ActiveRecord::Base
  acts_as_copy_target

  belongs_to :time_table
  belongs_to :vehicle_journey

  def self.find_each_without_primary_key(&block)
    batch_size = 1000
    offset = 0

    loop do
      records = order(:time_table_id, :vehicle_journey_id).offset(offset).limit(batch_size).records

      records.each do |record|
        yield record
      end

      break if records.size < batch_size
      offset += batch_size
    end
  end

end
