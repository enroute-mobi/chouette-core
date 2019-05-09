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


  private

  def resource
    super.decorate(context: { line_referential: parent })
  end

  def collection
    scope = end_of_association_chain
    @line_notices = scope.paginate(page: params[:page])
  end

  def line_notice_params
    params.require(:line_notice).permit( :title, :content, :object_id, :import_xml)
    # TODO check if metadata needs to be included as param  t.jsonb "metadata", default: {}
  end
end
