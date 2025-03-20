module OptionsSupport
  extend ActiveSupport::Concern
  included do |into|
    extend Enumerize

    after_initialize do
      if self.attribute_names.include?('options') && options.nil?
        self.options = {}
      end
    end

    class << self

      def option name, opts={}
        @options ||= {}
        @options[name] = opts

        attribute_name =  opts[:name].presence || name
        store_accessor :options, attribute_name

        handle_serialize_option(attribute_name, opts)
        handle_enumerize_option(attribute_name, opts)
        handle_default_value_option(attribute_name, opts)
      end

      def options
        @options ||= {}
      end

      def options= options
        @options = options
      end

      private

      def handle_serialize_option attribute_name, opts
        serializer = opts[:serialize]
    
        define_method attribute_name do
          return nil unless respond_to?(:options)
    
          raw_value = options.stringify_keys[attribute_name.to_s]
          value = JSON.parse(raw_value) rescue raw_value

          return value unless serializer

          case serializer.class.name
          when 'Proc' then serializer.call(value)
          when 'Symbol' then send(serializer, value)
          else
            serializer.new.cast(value)
          end
        rescue => e
          Rails.logger.warn("Could not cast #{attribute_name}. value: #{value}, \n Error: #{e}")
          value
        end

        # Use fixed_serializer option to enable serialization on writer method
        # TODO: Should be the default behavior
        if serializer && opts[:fixed_serializer]
          define_method "#{attribute_name}=" do |value|
            super serializer.new.serialize(value)
          rescue => e
            Rails.logger.warn("Could not serialize #{attribute_name}: value: #{value}", e)
            raise e
          end
        end
      end

      def handle_enumerize_option attribute_name, opts
        enumerize attribute_name, in: opts[:enumerize], default: opts[:default_value] if opts.key?(:enumerize)
      end

      def handle_default_value_option attribute_name, opts
        if opts.key?(:default_value)
          after_initialize do
            if self.new_record? && self.send(attribute_name).nil?
              self.send("#{attribute_name}=", opts[:default_value])
            end
          end
        end
      end

    end
  end

  def option_def(name)
    name = name.to_s
    candidates = self.class.options.select do |k, v|
      k.to_s == name || v[:name]&.to_s == name
    end
    return candidates.values.last || {} if candidates.size < 2

    # if we have multiple candidates, it means that we have to filter on the `depend` value
    candidates.values.find do |opt|
      opt[:depends] && send(opt[:depends][:option])&.to_s == opt[:depends][:value].to_s
    end || {}
  end

  def visible_options
    (options || {}).select{|k, v| ! k.match(/^_/) && !option_def(k)[:hidden]}
  end

end
