class WorkbenchesController < BreadcrumbController

  defaults :resource_class => Workbench
  respond_to :html, :only => [:show]

  def show
    show! do
      build_breadcrumb :show
    end
  end

end
