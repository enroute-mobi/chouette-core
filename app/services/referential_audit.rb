class ReferentialAudit
  include PrettyOutput

  attr_reader :referential
  attr_accessor :interfaces_group
  attr_accessor :status

  def initialize referential
    @referential = referential
    @verbose = true
    @status = :new
    @number_of_lines = rand(100)
    init_output
  end

  def perform opts={}
    @number_of_lines.times do |i|
      @current_line = i
      @statuses += colorize("x", :red)
      print_state
      sleep 0.2
    end
    @status = :success
  end
end
