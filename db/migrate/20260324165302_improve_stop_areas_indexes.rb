# frozen_string_literal: true

class ImproveStopAreasIndexes < ActiveRecord::Migration[7.2]
  def up
    on_public_schema_only do
      # Reset registration_number for second/other duplicated
      other_ids = Chouette::StopArea.where.not(registration_number: nil)
                                    .group(:stop_area_provider_id, :registration_number)
                                    .having('count(*) > 1')
                                    .pluck(Arel.sql('unnest((array_agg(id))[2:])'))
      Chouette::StopArea.where(id: other_ids).update_all(registration_number: nil)

      change_table :stop_areas do |t|
        t.index %i[referent_id]
        t.index %i[stop_area_provider_id registration_number], unique: true
        t.remove_index name: 'index_stop_areas_on_referential_id_and_registration_number'
      end
    end
  end

  def down
    on_public_schema_only do
      change_table :stop_areas do |t|
        t.remove_index %i[referent_id]
        t.remove_index %i[stop_area_provider_id registration_number], unique: true
        t.index %i[stop_area_referential_id registration_number],
                name: 'index_stop_areas_on_referential_id_and_registration_number'
      end
    end
  end
end
