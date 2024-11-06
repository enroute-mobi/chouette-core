class OperationRunFacade
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper

  attr_reader :resource, :current_workbench

  def initialize(resource, current_workbench)
    @resource = resource
    @current_workbench = current_workbench
  end

  def criticity_span(criticity)
    color_map = {
      info: 'green',
      warning: 'gold',
      error: 'red'
    }

    color = color_map[criticity.to_sym]

    content_tag(:span, '', class: "span fa fa-circle text-enroute-chouette-#{color}") + criticity.text
  end

  #  Duplicate method of link_to_if_table in ApplicationHelper
  #  TODO : should be deleted with all this classe
  def link_to_if_table(condition, label, url)
    condition == false ? label = '-' : label
    link_to_if(condition, label, url)
  end

  def message_table_params
    criticity = TableBuilderHelper::Column.new(
      key: :criticity,
      attribute: ->(m) { criticity_span(m.criticity) },
      sortable: false
    )

    columns = [
      TableBuilderHelper::Column.new(key: :message, attribute: :full_message, sortable: false),
      TableBuilderHelper::Column.new(
        key: :source,
        attribute: lambda do |message|
          source_link = source_link(message)
          link_to_if_table(source_link.present?, '<span class="fa fa-link"></span>'.html_safe, source_link)
        end,
        sortable: false
      )
    ]

    columns.unshift(criticity) if resource.is_a?(Macro::List::Run)

    [columns, { cls: 'table' }]
  end

  def source_link(message)
    return nil unless display_referential_links? && message.source_type && message.source_id

    source_class = message.source_type&.constantize
    Chouette::ModelPathFinder.new(source_class, message.source_id, current_workbench, resource.referential).path
  end

  private

  def display_referential_links?
    return @display_referential_links if defined?(@display_referential_links)

    @display_referential_links = current_workbench && \
                                 (!resource.referential || current_workbench.find_referential(resource.referential.id))
  end

  class	PaginateLinkRenderer < WillPaginate::ActionView::LinkRenderer
    attr_reader :url_params

    def initialize(url_params)
      @url_params = url_params
      super()
    end

    protected

    def url(page)
      @template.url_for(url_params.merge(page: page))
    end
  end
end
