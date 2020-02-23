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

  def update_or_create?
    !destroyed?
  end

  def destroyed?
    type == DESTROYED
  end

  validate :resources_are_payloads, unless: :destroyed?
  validate :resources_are_identifiers, if: :destroyed?

  def resources_are_payloads
    resources.each do |resource_name, resource|
      unless resource.payload?
        errors.add resource_name, "payload required"
      end
    end
  end

  def resources_are_identifiers
    resources.each do |resource_name, resource|
      unless resource.attributes?
        errors.add resource_name, "resource  required"
        next
      end

      resource.attributes.each do |value|
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
    resource_name = resource_name.to_s

    define_method "#{resource_name}=" do |value|
      resources[resource_name].value = value
    end
    alias_method "#{resource_name.pluralize}=", "#{resource_name}="

    define_method "#{resource_name}" do
      resources[resource_name].value
    end
    alias_method resource_name.pluralize, "#{resource_name}"

    define_method "#{resource_name}_ids" do
      resources[resource_name].identifiers
    end

    resource_names << "#{resource_name}" << "#{resource_name}s"
  end

  def resources
    @resources ||= Hash.new { |h,k| h[k] = Resource.new }
  end

  class Resource

    attr_accessor :payload

    def attributes
      @attributes ||= []
    end

    def value=(value)
      case value
      when String
        self.payload = value
      when Array
        attributes.concat(value)
      else
        attributes << value
      end
    end

    def value
      payload || attributes
    end

    def payload?
      payload.present?
    end

    def attributes?
      !payload? and attributes.present?
    end

    def identifiers
      attributes.map { |a| a[:id] }
    end

  end

  def netex_source
    source = Netex::Source.new include_raw_xml: true
    source.transformers << Netex::Transformer::LocationFromCoordinates.new

    resources.each do |_, resource|
      if resource.payload?
        source.parse StringIO.new(resource.payload)
      end
    end

    source
  end

  class StopAreaReferential < WebhookEvent

    resource :stop_place
    resource :quay

  end

  class LineReferential < WebhookEvent

    resource :line
    resource :operator
    resource :network
    resource :notice

  end
end
