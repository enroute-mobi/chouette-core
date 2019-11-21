class StopAreaReferentialsController < ChouetteController

  defaults :resource_class => StopAreaReferential

  def show
    show! do
      @stop_area_referential = StopAreaReferentialDecorator.decorate(@stop_area_referential)
    end
  end

  def sync
    authorize resource, :synchronize?
    @sync = resource.stop_area_referential_syncs.build
    if @sync.save
      flash[:notice] = t('notice.stop_area_referential_sync.created')
    else
      flash[:error] = @sync.errors.full_messages.to_sentence
    end
    redirect_to resource
  end

  def stop_area_referential_params
    locales = []
    params[:locales].each do |_, locale|
      next if locale[:delete] == '1'

      locales << {
        code: StopAreaReferential.translate_code_to_internal(locale[:code]),
        default: locale[:default] == '1'
      }
    end

    stops_selection_displayed_fields = {}
    params[:stops_selection_displayed_fields].each do |k, v|
      stops_selection_displayed_fields[k] = v == '1'
    end

    route_edition_available_stops = {}
    params[:route_edition_available_stops].each do |k, v|
      route_edition_available_stops[k] = v == '1'
    end

    { locales: locales, stops_selection_displayed_fields: stops_selection_displayed_fields, route_edition_available_stops: route_edition_available_stops }
  end
end
