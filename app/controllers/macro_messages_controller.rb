# frozen_string_literal: true

class MacroMessagesController < Chouette::WorkbenchController
  defaults resource_class: Macro::Message

  respond_to :js

  belongs_to :macro_list_run
  belongs_to :macro_context_run, optional: true
  belongs_to :macro_run

  def index
    messages = collection.where(search_params).paginate(page: params[:page], per_page: 15)

    html = render_to_string(
      partial: 'macro_list_runs/macro_messages',
      locals: {
        messages: messages,
        facade: OperationRunFacade.new(@macro_list_run, @workbench)
      }
    )

    render json: { html: html }
  end

  private

  def search_params
    params.require(:search).permit(
      criticity: []
    )
  end
end
