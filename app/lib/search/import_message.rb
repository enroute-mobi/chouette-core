# frozen_string_literal: true

module Search
  class ImportMessage < Base
    attribute :text
    attribute :criticity
    attribute :file

    attr_accessor :import

    def searched_class
      ::Import::Message
    end

    def query(scope)
      Query::ImportMessage.new(scope)
                    .text(text)
                    .criticity(criticity)
                    .file(file)
    end

    def candidate_criticities
      %w[warning error]
    end

    class Order < ::Search::Order
      attribute :created_at, default: :desc
    end
  end
end
