# Proof of concept:
# -----------------
# Needs **heavy refactoring** if solution is accepted!!!!
# IOW Dare you critisizing my code ;)
module HstoreAtts

  class << self
    def get_format_for type
      formats.fetch(type, %r{.})
    end


    private

    def formats
       @__formats__ ||= {
         int: %r{\A \s* [-+]? \d+ \s* \z}x 
       }
    end

  end
  def hstore_attr store_name, att_name, allow_nil: false, validate: false, type: :int
    define_method "#{att_name}=" do | new_value |
      stored_value = new_value.nil? ? nil : new_value.to_s
      send(store_name)[att_name.to_s] = stored_value
    end

    define_method att_name.to_s do
      send(store_name).tap do | store |
        return nil unless store
        return store[att_name.to_s].to_i # TODO: Convert on provided type 
      end
    end

    if validate
      format = HstoreAtts.get_format_for(type)
      validation_name = "validate_format_of_#{att_name}"
      define_method validation_name do
        send(store_name).tap do | store |
          return true if store.nil? && allow_nil
          return errors.add(att_name.to_sym, 'Must not be nil') if store.nil?
          store_value = store[att_name.to_s]
          return true if store_value.nil? && allow_nil
          return errors.add(att_name.to_sym, 'Must not be nil') if store_value.nil?
          return true if format === store_value
          return errors.add(att_name.to_sym, "Value #{store_value.inspect} does not comply to specified format #{format.inspect}")
        end
      end
      validate validation_name
    end
  end

end
