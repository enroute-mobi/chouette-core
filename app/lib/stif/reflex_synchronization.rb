module Stif
  module ReflexSynchronization
    class << self
      attr_accessor :imported_count, :updated_count, :deleted_count, :providers_deleted_count, :processed

      def reset_counts
        self.imported_count = 0
        self.updated_count  = 0
        self.deleted_count  = 0
        self.processed      = []
        self.providers_deleted_count = 0
        @_stop_area_provider_cache   = {}
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

      def reset_defaut_referential
        @defaut_referential = nil
      end

      def defaut_referential
        @defaut_referential ||= StopAreaReferential.find_by(name: "Reflex")
      end

      def find_by_object_id objectid
        Chouette::StopArea.find_by(objectid: objectid)
      end

      def save_if_valid object
        if object.valid?
          object.save
        else
          Rails.logger.error "Reflex:sync - #{object.class.model_name} with objectid #{object.objectid} can't be saved - errors : #{object.errors.messages}"
        end
      end

      def synchronize
        reset_counts
        reset_defaut_referential

        start   = Time.now
        results = ICar::API.new(timeout: 120).process('getAll')
        log_processing_time("Process getAll", Time.now - start)
        stop_areas = results[:Quay] | results[:StopPlace]
        organisational_units = results[:OrganisationalUnit]

        time = Benchmark.measure do
          organisational_units.each do |entry|
            update_organisational_unit entry
          end

          stop_areas.each_slice(1000) do |entries|
            Chouette::StopArea.transaction do
              Chouette::StopArea.cache do
                entries.each do |entry|
                  self.create_or_update_stop_area entry
                  self.processed << entry['id']
                end
              end
            end
          end
        end
        log_processing_time("Create or update StopArea", time.real)

        time = Benchmark.measure do
          stop_areas.each_slice(1000) do |entries|
            Chouette::StopArea.transaction do
              Chouette::StopArea.cache do
                entries.map {|entry| self.stop_area_set_parent(entry) }
              end
            end
          end
        end
        log_processing_time("StopArea set parent", time.real)

        # Set deleted_at for item not returned by api since last sync
        time = Benchmark.measure { self.set_deleted_stop_area }
        log_processing_time("StopArea #{self.deleted_count} deleted", time.real)

        self.processed_counts
      end

      def set_deleted_stop_area
        deleted = Chouette::StopArea.where(deleted_at: nil).pluck(:objectid).uniq - self.processed.uniq
        deleted.each_slice(50) do |object_ids|
          Chouette::StopArea.where(objectid: object_ids).update_all(deleted_at: Time.now)
        end
        increment_counts :deleted_count, deleted.size
      end

      def stop_area_set_parent entry
        return false unless entry['parent'] || entry['derivedFromObjectRef']
        stop = self.find_by_object_id entry['id']
        return false unless stop

        if entry['parent']
          stop.parent = self.find_by_object_id entry['parent']
        end

        if entry['derivedFromObjectRef']
          stop.referent = self.find_by_object_id entry['derivedFromObjectRef']
        end
        save_if_valid(stop) if stop.changed?
      end

      def update_organisational_unit(entry)
        stop_area_provider = get_stop_area_provider entry['id']
        unless stop_area_provider
          Rails.logger.info "Unknown StopAreaProvider '#{entry['id']}' in Sesame referenced by ICar"
          return
        end

        stop_area_provider.name = entry["name"]
        stop_area_provider.save
      end

      def get_stop_area_provider objectid
        @_stop_area_provider_cache[objectid] ||= StopAreaProvider.find_by(objectid: objectid, stop_area_referential_id: defaut_referential.id)
      end

      def create_or_update_stop_area entry
        stop_area_provider = get_stop_area_provider(entry['dataSourceRef'])
        return unless stop_area_provider

        stop = stop_area_provider.stop_areas.find_or_create_by objectid: entry['id']
        {
          name:          'Name',
          object_version: 'version',
          postal_region:  'PostalRegion',
          city_name:      'Town',
        }.each do |k, v| stop[k] = entry[v] end

        if entry['gml:pos']
          stop['longitude'] = entry['gml:pos'][:lng]
          stop['latitude']  = entry['gml:pos'][:lat]
        end

        if entry['id'].include? 'monomodalStopPlace'
          stop.area_type = 'zdlp'
        elsif entry['id'].include? 'multimodalStopPlace'
          stop.area_type = 'lda'
        else
          stop.area_type = 'zdep'
        end

        # It seems that referent stop areas are related to the STIF 'FR1-ARRET_AUTO' stop area provider
        stop.is_referent = true if entry['dataSourceRef'] == 'FR1-ARRET_AUTO'

        stop.kind = :commercial
        stop.deleted_at = nil

        if stop.new_record?
          stop.confirmed_at = Time.now
          stop.created_at = Time.now
        end

        if stop.changed?
          stop.import_xml = entry[:xml]
          prop = stop.new_record? ? :imported_count : :updated_count
          increment_counts prop, 1
          save_if_valid(stop)
        end

        stop
      end

    end
  end
end
