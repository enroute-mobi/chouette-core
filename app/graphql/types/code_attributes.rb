# frozen_string_literal: true

module Types
  class CodeAttributes < BaseInputObject
    argument :code_space, String, required: true
    argument :value, String, required: true
  end
end
