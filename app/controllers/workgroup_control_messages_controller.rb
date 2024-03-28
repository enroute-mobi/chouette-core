# frozen_string_literal: true

class WorkgroupControlMessagesController < Chouette::WorkgroupController
  defaults resource_class: Control::Message, collection_name: 'control_messages'

  respond_to :js

  belongs_to :control_list_run
  belongs_to :control_run

  def index
    messages = collection.paginate(page: params[:page], per_page: 15)

    html = render_to_string(
      partial: 'control_list_runs/control_messages',
      locals: {
        messages: messages,
        facade: OperationRunFacade.new(@control_list_run, workgroup.owner_workbench)
      }
    )

    render json: { html: html }
  end
end
