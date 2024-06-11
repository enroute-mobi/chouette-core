class PublicationSetupDecorator < AF83::Decorator
  decorates PublicationSetup

  set_scope { context[:workgroup] }

  with_instance_decorator do |instance_decorator|
    instance_decorator.crud
  end

  define_instance_method :display_profile_options do
    displayed_profile_options = ""
    object.profile_options.each_pair do |key, value|
      displayed_profile_options += ", " if displayed_profile_options.present?
      displayed_profile_options += "#{key} : #{value}"
    end
    displayed_profile_options
  end
end
