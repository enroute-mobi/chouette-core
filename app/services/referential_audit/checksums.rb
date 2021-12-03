class ReferentialAudit
  class Checksums < Base

    def message(record, output: :console)
      "#{record.class.name} ##{record.id} has an inconsistent checksum"
    end

    def find_faulty
      faulty = []

      if @referential.referential_suite_id.present?
        checker = Proc.new do |collection|
          collection.select(:checksum, :checksum_source).find_each(batch_size: 200) do |model|
            expected_source = model.current_checksum_source(db_lookup: false)

            if model.checksum_source != expected_source
              faulty << model
              next
            end

            expected_checksum = Digest::SHA256.new.hexdigest(expected_source)
            if model.checksum != expected_checksum
              faulty << model
            end
          end
        end

        Chouette::ChecksumUpdater.new(@referential, updater: checker).update
      end

      faulty
    end
  end
end
