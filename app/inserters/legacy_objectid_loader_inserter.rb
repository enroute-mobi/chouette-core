# frozen_string_literal: true

# Define transient attributes required by Chouette::ObjectidFormatter::StifNetex
class LegacyObjectidLoaderInserter
  attr_reader :referential

  def initialize(target)
    @referential = target
  end

  def insert(model, _options = {})
    # Ignore models without objectid support
    return unless model.respond_to?(:objectid)

    model.with_transient(referential_id: referential.id)
    model.with_transient(referential_prefix: referential.prefix)

    return unless model.respond_to?(:route) || model.respond_to?(:line)

    model.with_transient(line_code: line_code(model))
  end

  # Retrives model line objectid by using intermediate caches
  def line_code(model)
    line_code_by_line_id(line_id(model), model: model)
  end

  # Extracts line_id from the given model, or nil if not associated line
  def line_id(model)
    return model.line_id if model.respond_to?(:line_id)

    line_ids_by_route_id[model.route_id] ||= model.route&.line_id
  end

  # Returns the line code in cache or uses the model line
  def line_code_by_line_id(line_id, model:)
    return nil unless line_id

    line_codes_by_line_id[line_id] ||=
      begin
        line = model.try(:line) || model.route&.line
        line&.get_objectid&.local_id
      end
  end

  private

  def line_codes_by_line_id
    @line_codes_by_line_id ||= {}
  end

  def line_ids_by_route_id
    @line_ids_by_route_id ||= {}
  end
end
