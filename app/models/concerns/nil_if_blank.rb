# frozen_string_literal: true

module NilIfBlank
  extend ActiveSupport::Concern

  included do
    before_save :nil_if_blank
  end

  class_methods do
    # to be overridden to set nullable attrs when empty
    def nullable_attributes
      []
    end
  end

  def nil_if_blank
    self.class.nullable_attributes.each { |attr| self[attr] = nil if self[attr].blank? }
  end
end
