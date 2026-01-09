# frozen_string_literal: true

module ControlMacro
  module Processable
    extend ActiveSupport::Concern

    include ::Processable

    protected

    def processed_attributes(attributes)
      attributes.slice(:workbench, :referential, :creator).merge({ name: name })
    end
  end
end
