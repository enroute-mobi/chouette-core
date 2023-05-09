class OperationRunFacade
  include Rails.application.routes.url_helpers
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::UrlHelper

  attr_reader :resource, :workbench, :display_referential_links

  def initialize(resource, display_referential_links: true)
    @resource = resource
    @display_referential_links = display_referential_links
    @workbench = resource.workbench
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
    Chouette::ModelPathFinder.new(message.source_type.constantize, message.source_id, workbench,
                                  resource.referential.present? ? resource.referential : nil).path
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
