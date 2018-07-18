class ReferentialAudit
  class Full
    include PrettyOutput

    attr_reader :referential
    attr_accessor :interfaces_group
    attr_accessor :status

    def self.register klass
      @items ||= []
      @items << klass
    end

    def self.items
      @items ||= []
    end

    def initialize referential
      @referential = referential
      @banner = "Full Audit on referential \"#{referential.name}\""
      @verbose = true
      @status = :new
      @number_of_lines = self.class.items.size
      @left_part = self.class.items.map(&:name).map(&:size).max + 10
      init_output
    end

    def perform opts={}
      referential.switch do
        self.class.items.each do |item|
          instance = item.new(referential)
          instance.perform(self)
          res = send("#{instance.status}_status")
          @statuses += res
          log instance.name + " " + "." * (@left_part - instance.name.size) + " "
          log res, append: true

          print_state
          @current_line += 1
        end
      end
    end

    def encode_string s
      s
    end

    def add_error error, criticity=:error
      @_errors ||= []
      @_errors << {kind: criticity, message: error}
    end

    def success_status
      colorize("✓", :green)
    end

    def warning_status
      colorize("-", :orange)
    end

    def error_status
      colorize("x", :red)
    end
  end
end

require_dependency 'referential_audit/base'
