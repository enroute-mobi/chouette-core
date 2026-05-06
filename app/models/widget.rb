# frozen_string_literal: true

class Widget < ActiveRecord::Base
  extend Enumerize

  class Setup < ApplicationStoreModel
    self.abstract_class = true
  end

  class Image < Setup
  end

  class Search < Setup
  end

  class StaticText < Setup
    attribute :content, :string

    validates :content, presence: true
  end

  belongs_to :dashboard, touch: true

  attribute :setup, :json

  enumerize :widget_type, in: %w[image search static_text]

  validates :name, :widget_type, presence: true
  validates :setup, store_model: true

  def setup
    return nil unless widget_type.in?(self.class.widget_type.values)

    @setup ||= self.class.const_get(widget_type.classify).new(options)
  end

  def setup=(*args)
    send(:options=, *args)
  end
end
