class LegacyOperationJob
  def initialize(operation, method = :perform, *arguments)
    @operation = operation
    @method = method
    @arguments = arguments
  end

  attr_reader :operation, :method, :arguments

  def display_name
    @display_name ||= "#{operation_class}##{operation_id}"
  end

  def operation_class
    @operation_class ||= operation.class.name
  end

  def operation_id
    operation.try(:id)
  end

  def workgroup_id
    @workgroup_id ||= operation.try(:workgroup)&.id
  end

  def workbench_id
    @workbench_id ||= operation.try(:workbench)&.id
  end

  def organisation_id
    @organisation_id ||= operation.try(:organisation)&.id
  end

  def dead_worker
    operation.try(:worker_died)
  end

  def max_attempts
    1
  end

  def setup_span(span)
    span.set_tag 'operation_class', operation_class
    span.set_tag 'operation_id', operation_id

    context.each do |name, value|
      span.set_tag name, value
    end
  end

  def context
    @context ||= {
      organisation: organisation_id,
      workgroup: workgroup_id,
      workbench: workbench_id
    }.delete_if { |_, v| v.blank? }
  end

  def log
    context_description = context.map { |k, v| "#{k}=#{v}" }.join(',')
    logger.info "Start Operation #{display_name} #{context_description}"
  end

  def logger
    Rails.logger
  end

  def perform
    # current_span = Datadog::Tracing.active_span
    # setup_span(current_span) if current_span

    log

    logger.tagged(display_name) do
      operation.send method, *arguments
    end
  end
end
