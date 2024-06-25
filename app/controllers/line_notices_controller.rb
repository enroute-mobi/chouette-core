# frozen_string_literal: true

class LineNoticesController < Chouette::LineReferentialController
  defaults resource_class: Chouette::LineNotice

  def index
    index! do |format|
      format.html do
        @line_notices = LineNoticeDecorator.decorate(
          @line_notices,
          context: {
            workbench: workbench,
            line_referential: line_referential
          }
        )
        if params[:q] && params[:q][:lines_id_eq].present?
          @filtered_line = Chouette::Line.find(params[:q][:lines_id_eq])
        end
      end
    end
  end

  def create
    create! do
      collection_url
    end
  end

  private

  def resource
    super.decorate(context: { workbench: workbench, line_referential: line_referential })
  end

  def sort_column
    line_referential.line_notices.column_names.include?(params[:sort]) ? params[:sort] : 'id'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  def collection
    @line_notices ||= begin
      @q = line_referential.line_notices.ransack(params[:q])
      @q.result(distinct: true).order(sort_column => sort_direction).paginate(page: params[:page])
    end
  end

  def line_notice_params
    @line_notice_params ||= params.require(:line_notice).permit(
      :title,
      :content,
      :object_id,
      :object_version,
      :line_provider_id
    )
    # TODO check if metadata needs to be included as param  t.jsonb "metadata", default: {}
  end
end
