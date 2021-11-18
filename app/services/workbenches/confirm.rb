module Workbenches
	class Confirm < ApplicationService
		attr_reader :confirmation_code, :organisation

		def initialize(params)
			@confirmation_code = params[:confirmation_code]
			@organisation = Organisation.find(params[:organisation_id])
		rescue ActiveRecord::RecordNotFound => e
			false
		end

		def call
			workbench = Workbench.pending.find_by_invitation_code!(confirmation_code)

			workbench.accept(confirmation_code)
			workbench.assign_attributes(prefix: organisation.code, organisation_id: organisation.id)

			workbench.save!
			workbench
		rescue ActiveRecord::RecordNotFound => e
		rescue ActiveRecord::RecordInvalid => e
			false
		end
	end
end
