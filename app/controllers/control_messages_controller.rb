class ControlMessagesController < ChouetteController
  include ApplicationHelper
  include PolicyChecker

	belongs_to :workbench
	belongs_to :control_list_run
	belongs_to :control_run

  defaults :resource_class => Control::Message

	def index
		respond_to do |format|
			format.js do
				render json: {
					html: render_to_string(
						partial: 'control_list_runs/control_messages',
						locals: {
							control_run: parent,
							facade: OperationRunFacade.new(control_list_run)
						}
					)
				}
			end
		end
	end

	alias control_run parent

	private

	def control_list_run
		control_run.control_list_run
	end
end
