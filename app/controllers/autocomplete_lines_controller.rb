class AutocompleteLinesController < ChouetteController
  include ReferentialSupport

  respond_to :json, only: :index

  protected

  def collection
    @lines = referential.line_referential.lines

    @lines = @lines
      .by_name(params[:q])
      .search(params[:q])
      .result
      .paginate(page: params[:page])
  end
end
