module Processable
  extend ActiveSupport::Concern

  included do
    has_many :processing_rules, as: :processable
  end
end
