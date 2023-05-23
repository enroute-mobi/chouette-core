# ! Don't use these helpers !
# See CHOUETTE-797
# Provides legacy path helpers to link a Line, a Company without the required Workbench
module DefaultPathHelper
  #####################
  #  Stop area referential
  #####################
  def default_stop_area_path(stop_area)
    with_default_workbench { default_stop_area_path!(stop_area) }
  end

  def default_stop_area_path!(stop_area)
    workbench_stop_area_referential_stop_area_path default_workbench(resource: stop_area), stop_area
  end

  def default_stop_area_routing_constraints_path(stop_area_referential)
    with_default_workbench do
      workbench_stop_area_referential_stop_area_routing_constraints_path default_workbench(stop_area_referential: stop_area_referential)
    end
  end

  #####################
  #  Line referential
  #####################
  def default_company_path(company)
    with_default_workbench { default_company_path!(company) }
  end

  def default_company_path!(company)
    workbench_line_referential_company_path default_workbench(resource: company), company
  end

  def default_network_path(network)
    with_default_workbench do
      workbench_line_referential_network_path default_workbench(resource: network), network
    end
  end

  def default_line_path(line)
    with_default_workbench { default_line_path!(line) }
  end

  def default_line_path!(line)
    workbench_line_referential_line_path default_workbench(resource: line), line
  end

  def default_companies_path(line_referential)
    with_default_workbench do
      workbench_line_referential_companies_path default_workbench(line_referential: line_referential)
    end
  end

  def default_line_notices_path(line_referential)
    with_default_workbench do
      workbench_line_referential_line_notices_path default_workbench(line_referential: line_referential)
    end
  end

  #####################
  #  Shape referential
  #####################
  def default_shapes_path(shape_referential)
    with_default_workbench do
      workbench_shape_referential_shapes_path default_workbench(shape_referential: shape_referential)
    end
  end

  private

  def default_workbench(attributes = {})
    attributes.reverse_merge!(current_organisation: current_organisation)
    WorkbenchLookup.new(attributes).workbench!
  end

  # Returns '#' if the default workbench can't be found and report error
  def with_default_workbench
    yield
  rescue NoDefaultWorkbenchError => e
    raise e if raise_error_without_default_workbench?

    Chouette::Safe.capture "Can't create default path", e
    '#'
  end

  def raise_error_without_default_workbench?
    Rails.env.test? || Rails.env.development?
  end

  # Find the best Workbench from: current_organisation, given resource and/or given line_referential
  class WorkbenchLookup
    def initialize(attributes = {})
      attributes.each { |k, v| send "#{k}=", v }
    end

    attr_accessor :resource, :current_organisation

    def candidate_workbenches
      current_organisation.workbenches
    end

    # Find the workbench associated to the given resource
    def resource_workbench
      return unless resource

      provider = resource.try(:line_provider) || resource.try(:stop_area_provider) || resource.try(:shape_provider)
      return unless provider

      candidate_workbench_id = provider.workbench_id
      candidate_workbenches.find_by id: candidate_workbench_id
    end

    def line_referential_id
      @line_referential_id ||= resource.try(:line_referential_id)
    end

    def line_referential=(line_referential)
      @line_referential_id = line_referential.id
    end

    # Find the workbench associated to the line referential
    def line_referential_workbench
      return unless line_referential_id

      candidate_workbenches.find_by line_referential_id: line_referential_id
    end

    def stop_area_referential_id
      @stop_area_referential_id ||= resource.try(:stop_area_referential_id)
    end

    def stop_area_referential=(stop_area_referential)
      @stop_area_referential_id = stop_area_referential.id
    end

    # Find the workbench associated to the stop_area referential
    def stop_area_referential_workbench
      return unless stop_area_referential_id

      candidate_workbenches.find_by stop_area_referential_id: stop_area_referential_id
    end

    def shape_referential
      @shape_referential ||= resource.try(:shape_referential)
    end

    attr_writer :shape_referential

    # Find the workbench associated to the shape referential
    def shape_referential_workbench
      return unless shape_referential

      candidate_workbenches.find_by(workgroup_id: shape_referential.workgroup.id)
    end

    def workbench
      @workbench ||= (resource_workbench || line_referential_workbench || stop_area_referential_workbench || shape_referential_workbench)
    end

    def workbench!
      raise NoDefaultWorkbenchError, "Can't find a default workbench for #{inspect}" unless workbench

      workbench
    end
  end

  class NoDefaultWorkbenchError < StandardError; end
end
