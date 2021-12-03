class ReferentialAudit
  class FullReferential
    include PrettyOutput

    attr_reader :referential
    attr_accessor :interfaces_group
    attr_accessor :status
    attr_accessor :output

    def self.register klass
      @items ||= []
      @items << klass
    end

    def self.items
      @items ||= []
    end

    def initialize referential
      @referential = referential
      @banner = "Full Audit on referential \"#{referential.name.truncate(30)}\" (#{referential.id})"
      @verbose = true
      @status = :new
      @number_of_lines = self.class.items.size
      @left_part = self.class.items.map(&:pretty_name).map(&:size).max + 10
      init_output
    end

    def perform opts={}
      Chouette::Benchmark.measure("referential", referential_id: referential.id) do
        CustomFieldsSupport.within_workgroup(referential.workgroup) do
          plain_output = !!opts.delete(:plain_output)
          @output = opts.delete(:output) || :console
          @status = :success
          referential.switch do
            self.class.items.each do |item|
              instance = item.new(referential)
              instance.perform(self)
              if @status == :success || @status == :warning && instance.status == :error
                @status = instance.status
              end
              res = send("#{instance.status}_status")
              @statuses += res
              log instance.pretty_name + " " + "." * (@left_part - instance.pretty_name.size) + " ", silent: plain_output
              log res, append: true, silent: plain_output
              unless plain_output
                print_state
              end
              @current_line += 1
            end
          end
          @banner += ": " + send("#{@status}_status")
          full_state
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
