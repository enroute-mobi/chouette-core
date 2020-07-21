module OptionsSupport
  extend ActiveSupport::Concern
  included do |into|
    after_initialize do
      if self.attribute_names.include?('options') && options.nil?
        self.options = {}
      end
    end

    def self.option name, opts={}
      attribute_name =  opts[:name].presence || name
      store_accessor :options, attribute_name

      if opts[:serialize]
        define_method attribute_name do
          val = options.stringify_keys[name.to_s]
          unless val.is_a? opts[:serialize]
            val = JSON.parse(val) rescue opts[:serialize].new
          end
          val
        end
      end

      if opts.key?(:default_value)
        after_initialize do
          if self.new_record? && self.send(attribute_name).nil?
            self.send("#{attribute_name}=", opts[:default_value])
          end
        end
      end

      if opts[:type].to_s == "boolean"
        alias_method "#{attribute_name}_without_cast", attribute_name
        define_method "#{attribute_name}_with_cast" do
          val = send "#{attribute_name}_without_cast"
          val.is_a?(String) ? ["1", "true"].include?(val) : val
        end
        alias_method attribute_name, "#{attribute_name}_with_cast"
      end

      # Add specific validation for dependent attributes on the parent attribute and value
      condition = ->(record){ record.send(opts[:depends][:option])&.to_s == opts[:depends][:value].to_s } if opts[:depends]

      @options ||= {}
      @options[name] = opts
    end

    def self.options
      @options ||= {}
    end

    def self.options= options
      @options = options
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

  def display_option_value option_name, context
    option = option_def(option_name)
    val = self.options[option_name.to_s]
    if option[:display]
      context.instance_exec(val, &option[:display])
    else
      if option[:type].to_s == "boolean"
        (val == "1" || val == "true") ? 'true'.t : 'false'.t
      else
        val
      end
    end
  end

end
