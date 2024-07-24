# frozen_string_literal: true

module Search
  class Import < AbstractImport
    AUTHORIZED_GROUP_BY_ATTRIBUTES = (superclass::AUTHORIZED_GROUP_BY_ATTRIBUTES + %w[creator]).freeze

    attr_accessor :workbench
  end
end
