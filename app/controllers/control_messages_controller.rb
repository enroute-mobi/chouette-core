# frozen_string_literal: true

class ControlMessagesController < Chouette::WorkbenchController
  defaults resource_class: Control::Message

  respond_to :js

  belongs_to :control_list_run
  belongs_to :control_context_run, optional: true
  belongs_to :control_run

  def index
    messages = collection.order(:id).paginate(page: params[:page], per_page: 15)

    html = render_to_string(
      partial: 'control_list_runs/control_messages',
      locals: {
        messages: messages,
        facade: OperationRunFacade.new(@control_list_run, @workbench)
      }
    )

    render json: { html: html }
  end
end
