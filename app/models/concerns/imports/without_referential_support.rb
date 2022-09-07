module Imports
	module WithoutReferentialSupport
		extend ActiveSupport::Concern

		# Overrides #import method to remove referential management
		def import
			Chouette::Benchmark.measure "import_#{import_type}", id: id do
				update status: 'running', started_at: Time.now

				import_without_status
				@status ||= 'successful'

				update status: @status, ended_at: Time.now
			end
		rescue => e
			update status: 'failed', ended_at: Time.now
			Chouette::Safe.capture "#{self.class.name} ##{id} failed", e
		ensure
			save

			# Invoke the freaky logic /o\
			notify_parent
			notify_state
		end
	end
end
