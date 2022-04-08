class MacroMessagesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

	belongs_to :workbench
	belongs_to :macro_list_run
	belongs_to :macro_run

  defaults :resource_class => Macro::Message

  def index
    respond_to do |format|
      format.js do
				render json: {
					html: render_to_string(
						partial: 'macro_list_runs/macro_messages',
						locals: {
              macro_run: parent,
							facade: OperationRunFacade.new(macro_list_run)
						}
					)
				}
			end
    end
  end

	alias macro_run parent

	private

	def macro_list_run
		macro_run.macro_list_run
	end
end
