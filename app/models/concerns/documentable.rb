# frozen_string_literal: true

module Documentable
  extend ActiveSupport::Concern

  included do
    has_many :document_memberships, as: :documentable, dependent: :delete_all
    has_many :documents, through: :document_memberships
  end
end
