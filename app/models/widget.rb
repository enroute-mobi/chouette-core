# frozen_string_literal: true

class Widget < ActiveRecord::Base
  extend Enumerize

  class Setup < ApplicationStoreModel
    self.abstract_class = true

    delegate :workbench, to: :parent
  end

  class Image < Setup
  end

  class Search < Setup
    belongs_to :saved_search, class_name: 'Search::Save'

    validates :saved_search_id, inclusion: { in: ->(r) { r.candidate_searches.pluck(:id) } },
                                if: :saved_search_id.to_proc

    delegate :graphical?, to: :search

    def candidate_searches
      workbench.saved_searches
    end

    def search
      @search ||= saved_search.search
    end

    def scope
      workbench.send(saved_search.resource_name)
    end

    def count
      search.search(scope).count
    end

    def chart
      search.chart(scope)
    end
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

  delegate :workbench, to: :dashboard

  def setup
    return nil unless widget_type.in?(self.class.widget_type.values)

    @setup ||= self.class.const_get(widget_type.classify).new(options).tap do |setup|
      setup.parent = self
    end
  end

  def setup=(*args)
    send(:options=, *args)
  end
end
