class AutocompleteLinesController < ChouetteController
  include ReferentialSupport

  respond_to :json, only: :index

  protected

  def collection
    @lines = referential.line_referential.lines

    filter = <<~SQL
      lines.number LIKE ?
      OR lines.name LIKE ?
      OR companies.name ILIKE ?
    SQL
    @lines = @lines
      .joins(:company)
      .where(
        filter,
        *Array.new(3, "%#{params[:q]}%")
      )
      .search(params[:q])
      .result
      .paginate(page: params[:page])
  end
end
