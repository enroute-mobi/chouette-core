class MergesController < ChouetteController
  include PolicyChecker
  include ActionView::Helpers::TagHelper
  include IconHelper
  include ReferentialsHelper

  defaults resource_class: Merge
  belongs_to :workbench

  respond_to :html

  def show
    @merge = merge.decorate(context: { workbench: workbench })
    @referential_processings = MergeProcessings.new(merge).build
    show!
  end

  def available_referentials
    autocomplete_collection = parent.referentials.mergeable
    autocomplete_collection = if params[:q].present?
                                autocomplete_collection.autocomplete(params[:q]).order(:name)
                              else
                                autocomplete_collection.order('created_at desc')
                              end

    render json: autocomplete_collection.select(:name, :id).limit(10).map { |r|
                   { text: decorate_referential_name(r), id: r.id }
                 }
  end

  def rollback
    authorize resource
    resource.rollback!
    redirect_to %i[workbench output]
  end

  protected
  
  alias merge resource
  alias workbench parent

  def build_resource
    super.tap do |merge|
      merge.creator = current_user.name
    end
  end

  private

  def merge_params
    merge_params = params.require(:merge).permit(:referential_ids, :notification_target, :merge_method)
    merge_params[:referential_ids] = merge_params[:referential_ids].split(',')
    merge_params[:user_id] ||= current_user.id
    merge_params
  end

  class MergeProcessings
    attr_reader :merge

    def initialize(merge)
      @merge = merge
    end

    def referential_ids
      referential_ids = merge.referential_ids
      referential_ids += [merge.new.id] if merge.new.present?
      referential_ids
    end
    
    def referential_processings
      @referential_processings ||= {}.tap do |referential_processings|
        referential_ids.each do |referential_id|
          referential_processings[referential_id] = {
            'workbench_macro_list_run' => nil,
            'workbench_control_list_run' => nil,
            'workgroup_control_list_run' => nil
          }
        end
      end
    end

    def build
      merge.processings.each do |processing|
        processed = processing.processed
        referential_id = processed.referential_id

        if processing.processed_type == 'Macro::List::Run'
          referential_processings[referential_id]['workbench_macro_list_run'] = processed
        elsif processing.processed_type == 'Control::List::Run' && processing.workgroup_id.nil?
          referential_processings[referential_id]['workbench_control_list_run'] = processed
        else
          referential_processings[referential_id]['workgroup_control_list_run'] = processed
        end
      end

      referential_processings
    end
  end
end
