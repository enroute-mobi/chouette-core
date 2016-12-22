module Stif
  module ReflexSynchronization
    class << self
      attr_accessor :imported_count, :updated_count, :deleted_count, :processed

      def reset_counts
        self.imported_count = 0
        self.updated_count  = 0
        self.deleted_count  = 0
        self.processed      = []
      end

      def processed_counts
        {
          imported: self.imported_count,
          updated: self.updated_count,
          deleted: self.deleted_count
        }
      end

      def log_processing_time message, time
        Rails.logger.info "Reflex:sync - #{message} done in #{time} seconds"
      end

      def increment_counts prop_name, value
        self.send("#{prop_name}=", self.send(prop_name) + value)
      end

      def defaut_referential
        StopAreaReferential.find_by(name: "Reflex")
      end

      def find_by_object_id objectid
        Chouette::StopArea.find_by(objectid: objectid)
      end

      def synchronize
        self.reset_counts
        ['getOR', 'getOP'].each do |method|
          start   = Time.now
          results = Reflex::API.new().process(method)
          log_processing_time("Process #{method}", Time.now - start)
          stop_areas = results[:Quay] | results[:StopPlace]

          time = Benchmark.measure do
            stop_areas.each do |entry|
              next unless is_valid_type_of_place_ref?(method, entry)
              entry['TypeOfPlaceRef'] = self.stop_area_area_type entry, method
              self.create_or_update_stop_area entry
              self.processed << entry['id']
            end
          end
          log_processing_time("Create or update StopArea", time.real)

          time = Benchmark.measure do
            stop_areas.map{|entry| self.stop_area_set_parent(entry)}
          end
          log_processing_time("StopArea set parent", time.real)
        end

        # Set deleted_at for item not returned by api since last sync
        time = Benchmark.measure { self.set_deleted_stop_area }
        log_processing_time("StopArea #{self.deleted_count} deleted", time.real)
        self.processed_counts
      end

      def is_valid_type_of_place_ref? method, entry
        return true if entry["TypeOfPlaceRef"].nil?
        return true if method == 'getOR' && ['ZDL', 'LDA', 'ZDE'].include?(entry["TypeOfPlaceRef"])
        return true if method == 'getOP' && ['ZDE', 'ZDL'].include?(entry["TypeOfPlaceRef"])
      end

      def stop_area_area_type entry, method
        type = entry['type'] == 'Quay' ? 'zde' : entry['TypeOfPlaceRef']
        type = "#{type.to_s}#{method.last}" unless type == 'LDA'
        type.downcase
      end

      def set_deleted_stop_area
        deleted = Chouette::StopArea.where(deleted_at: nil).pluck(:objectid).uniq - self.processed.uniq
        deleted.each_slice(50) do |object_ids|
          Chouette::StopArea.where(objectid: object_ids).update_all(deleted_at: Time.now)
        end
        increment_counts :deleted_count, deleted.size
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
        access.save if access.valid? && access.changed?
      end

      def create_or_update_stop_area entry
        stop = Chouette::StopArea.find_or_create_by(objectid: entry['id'])
        stop.deleted_at            = nil
        stop.stop_area_referential = self.defaut_referential
        {
          :name           => 'Name',
          :area_type      => 'TypeOfPlaceRef',
          :object_version => 'version',
          :zip_code       => 'PostalRegion',
          :city_name      => 'Town'
        }.each do |k, v| stop[k] = entry[v] end

        if stop.changed?
          stop.creation_time = entry[:created]
          stop.import_xml    = entry[:xml]
          prop = stop.new_record? ? :imported_count : :updated_count
          increment_counts prop, 1
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
