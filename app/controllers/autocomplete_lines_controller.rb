class AutocompleteLinesController < ChouetteController
  include ReferentialSupport

  respond_to :json, only: :index

  protected

  def collection
    @lines = referential.line_referential.lines

    @lines = @lines
      .joins(:company)
      .where('
        lines.number LIKE ?
        OR lines.name LIKE ?
        OR companies.name ILIKE ?',
        *Array.new(3, "%#{params[:q]}%")
      )
      .search(params[:q])
      .result
      .paginate(page: params[:page])
  end
end
