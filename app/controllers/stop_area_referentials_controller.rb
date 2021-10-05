class StopAreaReferentialsController < ChouetteController
  belongs_to :workbench
  defaults resource_class: StopAreaReferential, singleton: true

  def show
    show! do
      @stop_area_referential = StopAreaReferentialDecorator.decorate(@stop_area_referential, context: { workbench: @workbench })
      @connection_links = ConnectionLinkDecorator.decorate(@stop_area_referential.connection_links.order("updated_at desc").limit(5))
    end
  end

  def edit
    authorize resource
    edit!
  end

  def update
    authorize resource
    update!
  end

  def sync
    authorize resource, :synchronize?
    @sync = resource.stop_area_referential_syncs.build
    if @sync.save
      flash[:notice] = t('notice.stop_area_referential_sync.created')
    else
      flash[:error] = @sync.errors.full_messages.to_sentence
    end
    redirect_to [ @workbench, :stop_area_referential ]
  end

  protected

  def stop_area_referential_params
    locales = []
    params[:locales].each do |_, locale|
      next if locale[:delete] == '1'

      locales << {
        code: StopAreaReferential.translate_code_to_internal(locale[:code]),
        default: locale[:default] == '1'
      }
    end if params[:locales]

    stops_selection_displayed_fields = {}
    params[:stops_selection_displayed_fields].each do |k, v|
      stops_selection_displayed_fields[k] = v == '1'
    end if params[:stops_selection_displayed_fields]

    route_edition_available_stops = {}
    params[:route_edition_available_stops].each do |k, v|
      route_edition_available_stops[k] = v == '1'
    end if params[:route_edition_available_stops]

    { locales: locales, stops_selection_displayed_fields: stops_selection_displayed_fields, route_edition_available_stops: route_edition_available_stops }
  end
end
