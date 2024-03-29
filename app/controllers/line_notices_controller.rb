# frozen_string_literal: true

class LineNoticesController < Chouette::LineReferentialController
  include PolicyChecker
  include ApplicationHelper

  defaults :resource_class => Chouette::LineNotice

  before_action :load_line

  def index
    index! do |format|
      format.html {
        @line_notices = LineNoticeDecorator.decorate(
          @line_notices.order('created_at DESC'),
          context: {
            workbench: workbench,
            line_referential: line_referential,
            line: @line
          }
        )
      }
    end
  end

  def create
    build_resource
    create! do
      if @line
        @line.line_notices << @line_notice
        @line.save
        [workbench, :line_referential, @line, :line_notices]
      else
        [workbench, :line_referential, :line_notices]
      end
    end
  end

  def detach
    @line.update line_notice_ids: (@line.line_notice_ids - [params[:id].to_i])
    redirect_to [workbench, :line_referential, @line, :line_notices]
  end

  alias_method :line_referential, :parent

  private

  def build_resource
    get_resource_ivar || super.tap do |line_notice|
      line_notice.line_provider ||= workbench.default_line_provider
    end
  end

  def resource
    super.decorate(context: { workbench: workbench, line_referential: line_referential })
  end

  def sort_column
    (line_referential.line_notices.column_names).include?(params[:sort]) ? params[:sort] : 'id'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ?  params[:direction] : 'asc'
  end

  def collection
    @line_notices ||= begin
      scope = line_referential.line_notices
      scope = scope.joins(:lines).where('lines.id': @line.id) if @line
      @filtered_line = Chouette::Line.find(params[:q][:lines_id_eq]) if params[:q] && params[:q][:lines_id_eq].present?
      @q = scope.ransack(params[:q])
      if sort_column && sort_direction
        line_notices ||= @q.result(:distinct => true).order(sort_column + ' ' + sort_direction).paginate(:page => params[:page])
      else
        line_notices ||= @q.result(:distinct => true).order(:number).paginate(:page => params[:page])
      end
      line_notices
    end
  end

  def line_notice_params
    params.require(:line_notice).permit( :title, :content, :object_id, :object_version)
    # TODO check if metadata needs to be included as param  t.jsonb "metadata", default: {}
  end

  def load_line
    @line = parent.lines.find(params[:line_id]) if params[:line_id]
  end
end
