class AutocompleteLinesController < ChouetteController
  include ReferentialSupport

  respond_to :json, only: :index

  protected

  def collection
    @lines = referential.line_referential.lines

    filter = <<~SQL
      number LIKE ?
      OR name LIKE ?
    SQL
    @lines = @lines
      .where(
        filter,
        *Array.new(2, "#{params[:q]}%")
      )
      .search(params[:q])
      .result
      .paginate(page: params[:page])
  end
end
