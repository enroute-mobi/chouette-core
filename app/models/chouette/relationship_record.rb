# frozen_string_literal: true

module Chouette
  class RelationshipRecord < Referential::ActiveRecord
    self.abstract_class = true

    class << self
      def find_each_without_primary_key
        batch_size = 1000
        offset = 0

        loop do
          records = order(self.column_names).offset(offset).limit(batch_size).records

          records.each do |record|
            yield record
          end

          break if records.size < batch_size
          offset += batch_size
        end
      end

    end

  end
end
