module Merge::Referential

  class Base

    def initialize(merge, referential)
      @referential, @merge = referential, merge
    end
    attr_reader :referential, :merge
    alias source referential

    delegate :new, :workbench, :workgroup, to: :merge

    def logger
      # FIXME
      @logger ||= ActiveSupport::TaggedLogging.new(Rails.logger)
    end

  end

  class Batch

    def initialize(merge_context, models)
      @merge_context, @models = merge_context, models
    end
    attr_reader :merge_context, :models

    delegate :source, :new, to: :merge_context

  end

  class BatchAssociation

    def initialize(batch)
      @batch = batch
    end
    attr_reader :batch
    delegate :source, :new, to: :batch

  end

  class MetadatasMerger
    attr_reader :merge_metadatas, :referential
    def initialize(merge_referential, referential)
      @merge_metadatas = merge_referential.metadatas
      @referential = referential
    end

    delegate :metadatas, to: :referential, prefix: :referential

    def merge
      referential_metadatas.each do |metadata|
        merge_one metadata
      end
    end

    def merged_line_metadatas(line_id)
      merge_metadatas.select do |m|
        m.line_ids.include? line_id
      end
    end

    def merge_one(metadata)
      metadata.line_ids.each do |line_id|

        line_metadatas = merged_line_metadatas(line_id)

        metadata.periodes.each do |period|
          line_metadatas.each do |m|
            m.periodes = Range.remove(m.periodes, period)
          end

          attributes = {
            line_ids: [line_id],
            periodes: [period],
            referential_source_id: referential.id,
            created_at: metadata.created_at, # TODO check required dates
            flagged_urgent_at: metadata.urgent? ? Time.now : nil
          }

          # line_metadatas should not contain conflicted metadatas
          merge_metadatas << ReferentialMetadata.new(attributes)
        end
      end
    end

    def empty_metadatas
      merge_metadatas.select { |m| m.periodes.empty? }
    end
  end

end
