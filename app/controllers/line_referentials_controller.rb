class LineReferentialsController < BreadcrumbController

  defaults :resource_class => LineReferential

  def sync
    @sync = resource.line_referential_syncs.build
    if @sync.save
      flash[:notice] = t('notice.line_referential_sync.created')
    else
      flash[:error] = @sync.errors.full_messages.to_sentence
    end
    redirect_to resource
  end

  protected

  def begin_of_chain
    current_organisation
  end

  def line_referential_params
    params.require(:line_referential).permit(:sync_interval)
  end

end
