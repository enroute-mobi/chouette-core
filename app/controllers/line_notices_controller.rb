# frozen_string_literal: true

class LineNoticesController < Chouette::LineReferentialController
  defaults resource_class: Chouette::LineNotice

  def index
    index! do |format|
      format.html do
        @line_notices = LineNoticeDecorator.decorate(
          collection,
          context: {
            workbench: workbench,
            line_referential: line_referential
          }
        )
      end
    end
  end

  def create
    create! do
      collection_url
    end
  end

  protected

  def scope
    parent.line_notices
  end

  def search
    @search ||= Search::LineNotice.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search scope
  end

  private

  def resource
    super.decorate(context: { workbench: workbench, line_referential: line_referential })
  end

  def line_notice_params
    @line_notice_params ||= params.require(:line_notice).permit(
      :title,
      :content,
      :object_id,
      :object_version,
      :line_provider_id,
      codes_attributes: [:id, :code_space_id, :value, :_destroy]
    )
    # TODO check if metadata needs to be included as param  t.jsonb "metadata", default: {}
  end
end
