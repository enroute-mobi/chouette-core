module Workbenches
	class AcceptInvitation < ApplicationService
		attr_reader :confirmation_code, :organisation_id

		def initialize(confirmation_code:, organisation_id:)
			@confirmation_code = confirmation_code
			@organisation_id = organisation_id
		end

		def call
			organisation = Organisation.find(organisation_id)
			workbench = Workbench.pending.find_by_invitation_code!(confirmation_code)

			ActiveRecord::Base.transaction do
				workbench.update(prefix: organisation.code, organisation_id: organisation.id)
				workbench.accept!(confirmation_code)
			end

			workbench
		rescue ActiveRecord::RecordNotFound => e
		rescue ActiveRecord::RecordInvalid => e
			byebug
			false
		end
	end
end
