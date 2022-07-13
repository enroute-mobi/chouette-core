class GetLineDocument < ApplicationService
	attr_reader :referential, :registration_number, :document_type

	def initialize(referential:, registration_number:, document_type:)
		@referential = referential
		@registration_number = registration_number
		@document_type = document_type
	end

	def call
		document = line
			.documents
			.joins(:document_type)
			.merge(DocumentType.where(name: @document_type))
			.where('validity_period @> CURRENT_DATE')
			.order(updated_at: :desc)
			.first

		raise DocumentNotFoundError unless document

		document
	end

	def line
		relation = referential.lines.where(registration_number: registration_number)

		raise TooManyLinesError if relation.many?

		line = relation.first

		raise LineNotFoundError unless line

		line
	end

	class TooManyLinesError < StandardError; end
	class LineNotFoundError < StandardError; end
	class DocumentNotFoundError < StandardError; end
end
