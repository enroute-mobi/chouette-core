module Stif
  module ReflexSynchronization
    class << self
      def defaut_referential
        StopAreaReferential.find_by(name: "Reflex")
      end

      def find_by_object_id objectid
        Chouette::StopArea.find_by(objectid: objectid)
      end

      def synchronize
        tstart           = Time.now
        client           = Reflex::API.new
        processed        = []
        initial_count    = Chouette::StopArea.where(deleted_at: nil).count

        ['getOR', 'getOP'].each do |method|
          start   = Time.now
          results = client.process method
          Rails.logger.info "Reflex:sync - Process #{method} done in #{Time.now - start} seconds"
          results.each do |type, entries|
            Rails.logger.info "Reflex:sync - #{entries.count} #{type} retrieved"
          end

          # Create or update stop_area for every quay, stop_place
          stop_areas = results[:Quay] | results[:StopPlace]

          start = Time.now
          stop_areas.each do |entry|
            next unless is_valid_type_of_place_ref?(method, entry)
            processed << entry['id']
            self.create_or_update_stop_area entry
          end
          Rails.logger.info "Reflex:sync - Create or update StopArea done in #{Time.now - start} seconds"

          # Walk through every entry and set parent stop_area
          start = Time.now
          stop_areas.each do |entry|
            self.stop_area_set_parent entry
          end
          Rails.logger.info "Reflex:sync - StopArea set parent done in #{Time.now - start} seconds"
        end
        {
          imported: Chouette::StopArea.where(deleted_at: nil).count - initial_count,
          deleted: self.set_deleted_stop_area(processed.uniq).size
        }
      end

      def is_valid_type_of_place_ref? method, entry
        return true if entry["TypeOfPlaceRef"].nil?
        return true if method == 'getOR' && ['ZDL', 'LDA', 'ZDE'].include?(entry["TypeOfPlaceRef"])
        return true if method == 'getOP' && ['ZDE'].include?(entry["TypeOfPlaceRef"])
      end

      def set_deleted_stop_area processed
        start   = Time.now
        deleted = Chouette::StopArea.where(deleted_at: nil).pluck(:objectid).uniq - processed
        deleted.each_slice(50) do |object_ids|
          Chouette::StopArea.where(objectid: object_ids).update_all(deleted_at: Time.now)
        end
        Rails.logger.info "Reflex:sync - StopArea #{deleted.size} stop_area deleted since last sync in #{Time.now - start} seconds"
        deleted
      end

      def stop_area_set_parent entry
        return false unless entry['parent'] || entry['quays']
        stop = self.find_by_object_id entry['id']
        return false unless stop

        if entry['parent']
          stop.parent = self.find_by_object_id entry['parent']
          stop.save! if stop.changed
        end

        if entry['quays']
          entry['quays'].each do |id|
            children = self.find_by_object_id id
            next unless children
            children.parent = stop
            children.save! if children.changed?
          end
        end
      end

      def access_point_access_type entry
        if entry['IsEntry'] ==  'true' && entry['IsExit'] == 'true'
          'in_out'
        elsif entry['IsEntry'] == 'true'
          'in'
        elsif entry['IsExit'] == 'true'
          'out'
        end
      end

      def create_or_update_access_point entry, stop_area
        access = Chouette::AccessPoint.find_or_create_by(objectid: "dummy:AccessPoint:#{entry['id'].tr(':', '')}")
        # Hack, on save object_version will be incremented by 1
        entry['version']   = entry['version'].to_i + 1  if access.persisted?
        access.access_type = self.access_point_access_type(entry)
        access.stop_area = stop_area
        {
          :name           => 'Name',
          :object_version => 'version',
          :zip_code       => 'PostalRegion',
          :city_name      => 'Town'
        }.each do |k, v| access[k] = entry[v] end
        access.save! if access.changed?
      end

      def create_or_update_stop_area entry
        stop = Chouette::StopArea.find_or_create_by(objectid: entry['id'])
        stop.deleted_at            = nil
        stop.stop_area_referential = self.defaut_referential
        {
          :name           => 'Name',
          :area_type      => 'type',
          :object_version => 'version',
          :zip_code       => 'PostalRegion',
          :city_name      => 'Town'
        }.each do |k, v| stop[k] = entry[v] end

        if stop.changed?
          stop.creation_time = entry[:created]
          stop.import_xml = entry[:xml]
          stop.save!
        end
        # Create AccessPoint from StopPlaceEntrance
        if entry[:stop_place_entrances]
          entry[:stop_place_entrances].each do |entrance|
            self.create_or_update_access_point entrance, stop
          end
        end
        stop
      end
    end
  end
end
