class ControlMessagesController < ActionController::Base
  include Pundit::Authorization

	respond_to :js
	inherit_resources

	belongs_to :workbench
	belongs_to :control_list_run
	belongs_to :control_context_run, optional: true
	belongs_to :control_run

  def index
		authorize Control::Message
    messages = collection.paginate(page: params[:page], per_page: 15)

		html = render_to_string(
			partial: 'control_list_runs/control_messages',
			locals: {
				messages: messages,
				facade: OperationRunFacade.new(@control_list_run)
			}
		)

		render json: { html: html }
  end

	protected

	def pundit_user
    UserContext.new(current_user, workbench: @workbench)
  end

end
