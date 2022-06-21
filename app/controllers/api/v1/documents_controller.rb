class Api::V1::DocumentsController < Api::V1::WorkbenchController
  respond_to :json, only: [:create]

  def create
    document = Document.create! document_params

    render json: document, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { status: 'error', message: e }, status: 400
  end

  private

	def document_params
		params
			.require(:document)
			.permit(
				:name,
				:description,
				:file,
				:document_type,
				:document_provider,
				validity_period: [:from, :to],
				codes: [:code_space, :value],
			)
			.with_defaults(codes: [])
			.tap do |document_params|
				document_params[:codes].each do |code|
					code[:code_space_id] = current_workbench.workgroup.code_spaces.find_by(short_name: code.delete(:code_space))&.id
				end

				document_params[:codes_attributes] = document_params.delete(:codes)
				document_params[:document_type_id] = current_workbench.workgroup.document_types.find_by(name:  document_params.delete('document_type'))&.id
				document_params[:document_provider_id] = current_workbench.document_providers.find_by(name: document_params.delete('document_provider'))&.id
			end
  end
end
