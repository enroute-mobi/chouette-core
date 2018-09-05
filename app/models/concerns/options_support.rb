module OptionsSupport
  extend ActiveSupport::Concern
  included do
    def self.option name, opts={}
      store_accessor :options, name

      if opts[:serialize]
        define_method name do
          JSON.parse(options[name.to_s]) rescue opts[:serialize].new
        end
      end

      if opts[:type].to_s == "boolean"
        define_method "#{name}_with_cast" do
          val = send "#{name}_without_cast"
          val.is_a?(String) ? ["1", "true"].include?(val) : val
        end
        alias_method_chain name, :cast
      end

      if !!opts[:required]
        if opts[:depends]
          validates name, presence: true, if: ->(record){ record.send(opts[:depends][:option]) == opts[:depends][:value]}
        else
          validates name, presence: true
        end
      end
      @options ||= {}
      @options[name] = opts

      if block_given?
        yield Export::OptionProxy.new(self, opts.update(name: name))
      end
    end

    def self.options
      @options ||= {}
    end

    def self.options= options
      @options = options
    end
  end

  def visible_options
    (options || {}).select{|k, v| ! k.match  /^_/}
  end

  def display_option_value option_name, context
    option = self.class.options[option_name.to_sym]
    val = self.options[option_name.to_s]
    if option[:display]
      context.instance_exec(val, &option[:display])
    else
      if option[:type].to_s == "boolean"
        val == "1" ? 'true'.t : 'false'.t
      else
        val
      end
    end
  end

end
