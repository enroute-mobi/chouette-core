# frozen_string_literal: true

class LineNoticeMembershipsController < Chouette::LineReferentialController
  defaults resource_class: Chouette::LineNoticeMembership

  belongs_to :line, parent_class: Chouette::Line

  def index # rubocop:disable Metrics/MethodLength
    index! do |format|
      format.html do
        @line_notice_memberships = LineNoticeMembershipDecorator.decorate(
          collection.includes(:line_notice),
          context: {
            workbench: workbench,
            line_referential: line_referential,
            line: line
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

  def destroy
    destroy! do
      collection_url
    end
  end

  protected

  def build_resource
    get_resource_ivar || set_resource_ivar(
      apply_scopes_if_available(
        line_provider_for_build.line_notices
      ).send(method_for_build, resource_params[0].merge(line_referential: line_referential, lines: [line]))
    )
  end

  def authorize_resource_class
    authorize_policy(parent_policy, nil, Chouette::LineNotice)
  end

  def parent_for_parent_policy
    line
  end

  private

  def resource
    super.decorate(context: { workbench: workbench, line_referential: line_referential, line: line })
  end

  def scope
    parent.line_notice_memberships
  end

  def search
    @search ||= Search::LineNoticeMembership.from_params(params, workbench: workbench)
  end

  def collection
    @collection ||= search.search scope
  end

  def resource_params_method_name
    :line_notice_params
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

  def line_provider_id_from_params
    return nil unless params[:line_notice] && params[:line_notice][:line_provider_id]

    params[:line_notice][:line_provider_id]
  end

  def line
    association_chain
    get_parent_ivar(:line) || nil
  end
end
