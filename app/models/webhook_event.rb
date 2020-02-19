# {
#   "type": "destroyed",
#   "<single resource name>": { "id": "<identifier value 1>" },
#   "<single other resource name>": "<NeTEx XML payload for a resource>",
#   "<resource name>s": [
#     { "id": "<identifier value 1>" },
#     { "id": "<identifier value 2>" },
#     { "id": "<identifier value N>" },
#   ]
#   "<other resource name>s": "<NeTEx XML payload for several resources>"
# }
class WebhookEvent
  include ActiveModel::Model

  attr_accessor :type

  DESTROYED = "destroyed"
  TYPES = (%w(created updated) + [DESTROYED]).freeze

  validates :type, inclusion: { in: TYPES }

  def destroyed?
    type == DESTROYED
  end

  validate :resources_are_payloads, unless: :destroyed?
  validate :resources_are_identifiers, if: :destroyed?

  def resources_are_payloads
    resources.each do |resource_name, values|
      unless values.is_a?(String)
        errors.add resource_name, "payload required"
      end
    end
  end

  def resources_are_identifiers
    resources.each do |resource_name, values|
      unless values.is_a?(Array)
        errors.add resource_name, "hash required"
        next
      end

      values.each do |value|
        unless value.is_a?(Hash)
          errors.add resource_name, "hash required"
          next
        end

        unless value.has_key? :id
          errors.add resource_name, "identifier required"
          next
        end
      end
    end
  end

  def self.resource_names
    @resource_names ||= []
  end

  def self.resource(resource_name)
    define_method "#{resource_name}=" do |value|
      if value.is_a?(String)
        resources[resource_name] = value
      else
        # Array(hash) returns [[key, value], ...]
        values = value.is_a?(Array) ? value : [value]
        resources[resource_name] ||= []
        resources[resource_name].concat values
      end
    end
    alias_method "#{resource_name}s=", "#{resource_name}="

    define_method "#{resource_name}" do
      resources[resource_name]
    end
    alias_method "#{resource_name}s", "#{resource_name}"

    resource_names << "#{resource_name}" << "#{resource_name}s"
  end

  def resources
    @resources ||= Hash.new
  end

  class StopAreaReferential < WebhookEvent

    resource :stop_place
    resource :quay

  end

  class LineReferential < WebhookEvent

    resource :line
    resource :operator
    resource :network

  end
end
