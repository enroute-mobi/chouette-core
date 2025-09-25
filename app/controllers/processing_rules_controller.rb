# frozen_string_literal: true

# Manage ProcessingRule::Workbench on /workbenches/:id/processing_rules
class ProcessingRulesController < Chouette::WorkbenchController
  defaults resource_class: ProcessingRule::Workbench,
           route_instance_name: 'processing_rule_workbench',
           route_collection_name: 'processing_rule_workbenches'

  respond_to :html

  before_action only: :index do
    redirect_to params.merge(only_path: true, page: 1) if collection.out_of_bounds?
  end

  protected

  alias processing_rule resource

  def collection
    @processing_rules ||= decorate(workbench.processing_rules.paginate(page: params[:page], per_page: 30)) # rubocop:disable Naming/MemoizedInstanceVariableName(RuboCop)
  end

  def resource
    @processing_rule ||= decorate(workbench.processing_rules.find(params[:id])) # rubocop:disable Naming/MemoizedInstanceVariableName(RuboCop)
  end

  def build_resource
    @processing_rule ||= decorate(workbench.processing_rules.build(*resource_params)) # rubocop:disable Naming/MemoizedInstanceVariableName(RuboCop)
  end

  def decorate(processing_rule)
    ProcessingRuleDecorator.decorate(
      processing_rule,
      context: {
        workbench: workbench
      }
    )
  end

  private

  def processing_rule_params
    params.require(:processing_rule).permit(
      :processable_type,
      :control_list_id,
      :macro_list_id,
      :operation_step
    ).tap do |processing_rule_params|
      processing_rule_params[:required_tags_taggings_attributes] = build_tagging_attributes(params, :required_tags)
      processing_rule_params[:excluded_tags_taggings_attributes] = build_tagging_attributes(params, :excluded_tags)
    end
  end

  def build_tagging_attributes(params, association)
    new_ids = params[:processing_rule][association]
    existing_taggings = params[:action] == 'create' ? [] : processing_rule&.send("#{association}_taggings")

    BuildTaggingAttributes.new(new_ids, existing_taggings).attributes
  end

  class BuildTaggingAttributes
    def initialize(new_ids, existing_taggings)
      @existing_taggings = existing_taggings || []
      @new_ids = new_ids.reject(&:blank?).map(&:to_i)
    end

    def attributes
      return [] unless @new_ids.is_a?(Array)

      destroy_attrs + keep_or_new_attrs
    end

    private

    def destroy_attrs
      @existing_taggings.reject { |t| @new_ids.include?(t.tag_id) }.map { |t| { id: t.id, _destroy: 1 } }
    end

    def keep_or_new_attrs
      @new_ids.map do |tag_id|
        if (tagging = @existing_taggings.find { |t| t.tag_id == tag_id })
          { id: tagging.id, tag_id: tag_id }
        else
          { tag_id: tag_id }
        end
      end
    end
  end
end
