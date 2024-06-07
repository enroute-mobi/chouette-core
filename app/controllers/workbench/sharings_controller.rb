# frozen_string_literal: true

class Workbench
  class SharingsController < Chouette::WorkgroupController
    belongs_to :workbench

    defaults resource_class: ::Workbench::Sharing
    defaults collection_name: 'sharings', instance_name: 'workbench_sharing'

    def create
      create! { workbench_path }
    end

    def destroy
      destroy! { workbench_path }
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
