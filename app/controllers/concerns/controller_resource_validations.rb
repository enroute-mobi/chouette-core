# frozen_string_literal: true

module ControllerResourceValidations
  extend ActiveSupport::Concern

  protected

  def create_resource(object)
    validate_and_save_resource(object)
  end

  def update_resource(object, attributes)
    object.attributes = attributes[0]
    validate_and_save_resource(object)
  end

  def validate_and_save_resource(object)
    errors = controller_resource_validations(object)
    if errors.empty?
      object.save
    else
      object.valid? # validate the object before in order to compute all the other validations
      errors.each do |attribute, message|
        object.errors.add(attribute, message)
      end
      false
    end
  end

  def controller_resource_validations(_object)
    []
  end
end
