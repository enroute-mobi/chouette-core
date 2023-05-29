class MacroMessagesController < ActionController::Base
  include Pundit::Authorization

	respond_to :js
	inherit_resources

	belongs_to :workbench
	belongs_to :macro_list_run
	belongs_to :macro_context_run, optional: true
	belongs_to :macro_run

  def index
		authorize Macro::Message
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

	protected

	def pundit_user
    UserContext.new(current_user, workbench: @workbench)
  end

	private

  def search_params
    params.require(:search).permit(
      criticity: []
    )
  end
end
