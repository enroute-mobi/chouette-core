class LineNoticesController < ChouetteController
  include PolicyChecker
  include ApplicationHelper

  defaults :resource_class => Chouette::LineNotice
  belongs_to :line_referential

  def index
    index! do |format|
      format.html {
        @line_notices = LineNoticeDecorator.decorate(
          @line_notices.order('created_at DESC'),
          context: {
            line_referential: parent
          }
        )
      }
    end
  end

  def create
    create!
  end

  alias_method :line_referential, :parent

  private

  def resource
    super.decorate(context: { line_referential: parent })
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
    params.require(:line_notice).permit( :title, :content, :object_id)
    # TODO check if metadata needs to be included as param  t.jsonb "metadata", default: {}
  end
end
