# frozen_string_literal: true

class LineNoticeMembershipsCollectionsController < Chouette::LineReferentialController
  defaults resource_class: Chouette::LineNoticeMembership, collection_name: :line_notice_memberships

  belongs_to :line, parent_class: Chouette::Line

  protected

  def resource_url
    workbench_line_referential_line_line_notice_memberships_url(workbench, line)
  end

  private

  alias resource collection

  def update_resource(_, resource_params)
    line.update(*resource_params)
  end

  def line_notice_memberships_collection_params
    @line_notice_memberships_collection_params ||= begin
      r = params.require(:line).permit(:line_notice_ids)
      r[:line_notice_ids] = r[:line_notice_ids].split(',').map(&:to_i)
      r
    end
  end

  def line
    association_chain
    get_parent_ivar(:line) || nil
  end
end
