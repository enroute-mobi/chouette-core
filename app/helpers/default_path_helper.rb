# ! Don't use these helpers !
# See CHOUETTE-797
# Provides legacy path helpers to link a Line, a Company without the required Workbench
module DefaultPathHelper

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

  private

  def default_workbench(attributes = {})
    attributes.reverse_merge!(current_organisation: current_organisation)
    WorkbenchLookup.new(attributes).workbench!
  end

  # Returns '#' if the default workbench can't be found and report error
  def with_default_workbench
    yield
  rescue NoDefaultWorkbenchError => e
    if raise_error_without_default_workbench?
      raise e
    else
      Chouette::Safe.capture "Can't create default path", e
      '#'
    end
  end

  def raise_error_without_default_workbench?
    Rails.env.test? || Rails.env.development?
  end

  # Find the best Workbench from: current_organisation, given resource and/or given line_referential
  class WorkbenchLookup

    def initialize(attributes = {})
      attributes.each { |k,v| send "#{k}=", v }
    end

    attr_accessor :resource, :current_organisation

    def candidate_workbenches
      current_organisation.workbenches
    end

    # Find the workbench associated to the given resource
    def resource_workbench
      return unless resource

      candidate_workbench_id = resource.line_provider.workbench_id
      candidate_workbenches.find_by id: candidate_workbench_id
    end

    def line_referential_id
      @line_referential_id ||= (resource.line_referential_id if resource)
    end

    def line_referential=(line_referential)
      @line_referential_id = line_referential.id
    end

    # Find the workbench associated to the line referential
    def line_referential_workbench
      return unless line_referential_id
      candidate_workbenches.find_by line_referential_id: line_referential_id
    end

    def workbench
      @workbench ||= (resource_workbench || line_referential_workbench)
    end

    def workbench!
      if workbench
        workbench
      else
        raise NoDefaultWorkbenchError, "Can't find a default workbench for #{inspect}"
      end
    end

  end

  class NoDefaultWorkbenchError < StandardError; end

end
