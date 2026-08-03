# frozen_string_literal: true

class Widget < ActiveRecord::Base
  extend Enumerize

  class Setup < ApplicationStoreModel
    self.abstract_class = true

    extend Enumerize

    delegate :workbench, to: :parent

    def setup_data_cache?
      self.class.const_defined?(:CACHE_VERSION)
    end

    def data_available?
      !setup_data_cache? ||
        (parent.setup_data_cache.present? && parent.setup_data_cache['version'] == self.class::CACHE_VERSION)
    end

    def compute_setup_data_cache
      return nil unless valid?

      { 'data' => compute_data_cache, 'version' => self.class::CACHE_VERSION }
    end

    def retrieving_data_cache
      yield parent.setup_data_cache['data']
    rescue StandardError => e
      # An error occurred probably because the cached data is incompatible with what the widget was expecting.
      # For example, for Search, maybe the saved search changed and the cached data is now incompatible.
      # In that situation, we wait for the data to be recomputed.
      Chouette::Safe.capture("Error while retrieving setup cached data of Widget##{parent.id}", e)
      nil
    end

    protected

    def compute_data_cache
      raise NotImplementedError
    end
  end

  class Search < Setup
    REFERENTIAL_TARGET_SCOPES = %w[last_merged_dataset last_aggregated_dataset].freeze

    belongs_to :saved_search, class_name: 'Search::Save'

    attribute :target_scope, :string

    enumerize :target_scope, in: %w[workbench last_merged_dataset last_aggregated_dataset]

    validates :saved_search_id, inclusion: { in: ->(r) { r.candidate_searches.pluck(:id) } },
                                if: :saved_search_id.to_proc

    def candidate_searches
      if target_scope.in?(REFERENTIAL_TARGET_SCOPES)
        workbench.saved_searches.where(search_type: ::Search::Save::REFERENTIAL_SEARCH_TYPES)
      else
        workbench.saved_searches.where.not(search_type: ::Search::Save::REFERENTIAL_SEARCH_TYPES)
      end
    end

    def search
      @search ||= saved_search.search
    end

    def scope
      case target_scope
      when 'last_aggregated_dataset'
        source = workbench.workgroup.output&.current
      when 'last_merged_dataset'
        source = workbench.output&.current
      else
        source = workbench
      end

      if source
        source.send(saved_search.resource_name)
      else
        saved_search.searched_class.none
      end
    end
  end

  class Count < Search
    CACHE_VERSION = '2026-05-12'

    def candidate_searches
      super.non_graphical
    end

    def count
      retrieving_data_cache do |data|
        data
      end
    end

    protected

    def compute_data_cache
      search.search(scope).count
    end
  end

  class Chart < Search
    CACHE_VERSION = '2026-05-12'

    def candidate_searches
      super.graphical
    end

    def chart
      retrieving_data_cache do |data|
        converted_data = if search_chart.subgroup_by_attribute
                           data.map do |series_data|
                             series_data.symbolize_keys.tap do |d|
                               d[:data] = data_cache_to_chart_data(d[:data])
                             end
                           end
                         else
                           data_cache_to_chart_data(data)
                         end

        search_chart.data = converted_data
        search_chart
      end
    end

    protected

    def compute_data_cache
      if search_chart.subgroup_by_attribute
        search_chart.data.map do |series_data|
          series_data.stringify_keys.tap do |d|
            d['data'] = chart_data_to_data_cache(d['data'])
          end
        end
      else
        chart_data_to_data_cache(search_chart.data)
      end
    end

    private

    def search_chart
      @search_chart ||= search.chart(scope)
    end

    def chart_data_to_data_cache(data)
      data.to_a
    end

    def data_cache_to_chart_data(data)
      data.to_h
    end
  end

  class StaticText < Setup
    attribute :content, :string

    validates :content, presence: true
  end

  belongs_to :dashboard, touch: true

  attribute :setup, :json

  enumerize :widget_type, in: %w[count chart static_text], default: 'count'

  validates :name, :widget_type, presence: true
  validates :setup, store_model: true

  before_save :set_setup_data_cache, if: :set_setup_data_cache?

  scope :setup_data_cache_computable, -> { where(widget_type: %w[count chart]) }

  delegate :workbench, to: :dashboard
  delegate :data_available?, to: :setup

  def setup
    return nil unless widget_type.in?(self.class.widget_type.values)

    @setup ||= self.class.const_get(widget_type.classify).new(options).tap do |setup|
      setup.parent = self
    end
  end

  def setup=(*args)
    @setup = nil
    send(:options=, *args)
  end

  def update_setup_data_cache!
    set_setup_data_cache
    save!
  end

  # debug
  def clear_setup_data_cache!
    update_columns( # rubocop:disable Rails/SkipsModelValidations
      setup_data_cache: nil,
      setup_data_cache_updated_at: nil
    )
  end

  private

  def set_setup_data_cache?
    setup.setup_data_cache? && will_save_change_to_options?
  end

  def set_setup_data_cache
    self.setup_data_cache = setup.compute_setup_data_cache
    self.setup_data_cache_updated_at = Time.zone.now
  end
end
