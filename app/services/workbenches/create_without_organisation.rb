module Workbenches
	class CreateWithoutOrganisation < ApplicationService
		attr_reader :name, :workgroup

		def initialize(name:, workgroup:)
			@name = name
			@workgroup = workgroup
		end

		def call
			workbench = workgroup.workbenches.create!(name: name) do |w|
				w.line_referential      = workgroup.line_referential
        w.stop_area_referential = workgroup.stop_area_referential
        w.workgroup             = workgroup
				w.invitation_code				= "%06d" % (SecureRandom.random_number * 1000000)
        w.objectid_format       = 'netex'
			end
		end
	end
end
