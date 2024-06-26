# frozen_string_literal: true

class Workbench
  class SharingsController < Chouette::WorkgroupController
    belongs_to :workbench

    defaults resource_class: ::Workbench::Sharing
    defaults collection_name: 'sharings', instance_name: 'workbench_sharing'

    def create
      create! { workgroup_workbench_sharing_path(workgroup, @workbench, @workbench_sharing) }
    end

    def destroy
      destroy! { workbench_path }
    end

    protected

    def resource
      get_resource_ivar || set_resource_ivar(super.decorate(context: { workgroup: workgroup, workbench: @workbench }))
    end

    private

    def workbench_path
      workgroup_workbench_path(workgroup, @workbench)
    end

    def workbench_sharing_params
      @workbench_sharing_params ||= params.require(:sharing).permit(:name, :recipient_type, :recipient_id)
    end
  end
end
