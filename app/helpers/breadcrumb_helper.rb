module BreadcrumbHelper
  def breadcrumb_name(object, prop='name')
    name =
      if prop == 'name' && object.respond_to?(:full_name)
        object.full_name
      else
        "#{object.class.model_name.human} #{object.public_send(prop)}"
      end

    name.truncate(40).capitalize
  end
end
