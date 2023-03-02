class WorkgroupControlMessagesController < ChouetteController
  include Pundit::Authorization

  defaults collection_name: 'control_messages'

  respond_to :js

  belongs_to :workgroup
  belongs_to :control_list_run
  belongs_to :control_run

  def index
    authorize Control::Message
    messages = collection.paginate(page: params[:page], per_page: 15)

    html = render_to_string(
      partial: 'workgroup_control_list_runs/control_messages',
      locals: {
        messages: messages,
        facade: OperationRunFacade.new(@control_list_run)
      }
    )

    render json: { html: html }
  end

  protected

  def pundit_user
    UserContext.new(current_user, workgroup: @workgroup)
  end
end
