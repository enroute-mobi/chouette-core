class StatusesController < ChouetteController
  respond_to :json

  def index

    status = {
      referentials_blocked: Referential.blocked.count,
      imports_blocked: Import.blocked.count,
      compliance_check_sets_blocked: ComplianceCheckSet.blocked.count
    }
    status[:status] = global_status status
    render json: status.to_json
  end

  private

  def global_status status
    status.values.all?(&:zero?) ? 'ok' : 'ko'
  end
end
