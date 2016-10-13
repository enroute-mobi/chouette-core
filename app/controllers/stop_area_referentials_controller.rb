class StopAreaReferentialsController < BreadcrumbController

  defaults :resource_class => StopAreaReferential
  def sync
    @sync = resource.stop_area_referential_syncs.build
    if @sync.save
      flash[:notice] = t('notice.stop_area_referential_sync.created')
    else
      flash[:error] = @sync.errors.full_messages.to_sentence
    end
    redirect_to resource
  end

  protected
  def begin_of_chain
    current_organisation
  end

end
