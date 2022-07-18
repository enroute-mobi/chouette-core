module PublicationApis
	class GetLineDocument < ApplicationService
		attr_reader :referential, :registration_number, :document_type

		def initialize(referential:, registration_number:, document_type:)
			@referential = referential
			@registration_number = registration_number
			@document_type = document_type
		end

		def call
			line
				.documents
				.joins(:document_type)
				.where(document_types: { short_name: document_type })
				.where('validity_period @> CURRENT_DATE')
				.order(updated_at: :desc)
				.first!
		rescue ActiveRecord::RecordNotFound
			raise PublicationApi::DocumentNotFoundError
		end

		def line
			relation = referential.lines.where(registration_number: registration_number)

			raise PublicationApi::TooManyLinesError if relation.many?

			relation.first!
		rescue ActiveRecord::RecordNotFound
			raise PublicationApi::LineNotFoundError
		end
	end
end
