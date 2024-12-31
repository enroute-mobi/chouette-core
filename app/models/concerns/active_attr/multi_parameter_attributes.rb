module ActiveAttr::MultiParameterAttributes

  def assign_attributes(new_attributes, options = {})
    super(
      expand_multiparameter_attributes(new_attributes),
      options
    )
  end

  def expand_multiparameter_attributes(attributes)
    attributes ||= {}

    single_parameter_attributes = {}
    multi_parameter_attributes = {}

    attributes.each do |key, value|
      matches = key.match(/^(?<key>[^\(]+)\((?<index>\d+)i\)$/)

      unless matches
        single_parameter_attributes[key] = value
        next
      end

      args = (multi_parameter_attributes[matches['key']] ||= [])
      args[matches['index'].to_i - 1] = (value.present? ? value.to_i : nil)
    end

    single_parameter_attributes.merge(
      multi_parameter_attributes.inject({}) do |hash, (key, args)|
        if args.all?(&:present?)
          value = _attribute_type(key).new(*args) rescue nil
          hash.merge(key => value)
        else
          hash
        end
      end
    )
  end

end
