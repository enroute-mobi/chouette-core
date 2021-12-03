module PrettyOutput
  extend ActiveSupport::Concern

  included do
    def self.colorize txt, color, output = :console
      return txt if ENV['NO_COLOR'] = "true"

      if output == :html
        "<span style='color: #{color}'>#{txt}</span>"
      else
        color = {
          red: "31",
          green: "32",
          orange: "33",
        }[color] || "33"
        "\e[#{color}m#{txt}\e[0m"
      end
    end

    def self.status_color status
      color = :green
      color = :orange if status.to_s == "success_with_warnings"
      color = :red if status.to_s == "success_with_errors"
      color = :red if status.to_s == "error"
      color
    end
  end

  def init_output
    @_errors ||= []
    @messages ||= []
    @current_line ||= 0
    @statuses ||= ""
    @output = :console
  end

  def new_line count=1
    one_line = @output == :html ? '<br />' : "\n"
    one_line * count
  end

  def log msg, opts={}
    msg = msg.to_s
    msg = colorize msg, opts[:color] if opts[:color]
    @start_time ||= Time.now
    time = Time.now - @start_time
    @messages ||= []
    if opts[:append]
      _time, _msg = @messages.pop || []
      _time ||= time
      _msg ||= ""
      @messages.push [_time, _msg+msg]
    elsif opts[:replace]
      @messages.pop
      @messages << [time, msg]
    else
      @messages << [time, msg]
    end
    print_state true unless opts[:silent]
  end

  def colorize txt, color
    self.class.colorize txt, color, @output
  end

  def term_width
    @_term_width ||= %x(tput cols).to_i rescue 100
  end

  def status_width
    @_status_width ||= begin
      term_width - padding - 10
    end
  end

  def status_height
    @_status_height ||= begin
      term_height = %x(tput lines).to_i rescue 50
      term_height - 3
    end
  end

  def number_of_lines
    @number_of_lines ||= 1
  end

  def padding
    @padding ||= [1, Math.log([number_of_lines, 1].max, 10).ceil()].max
  end

  def print_state force=false
    return unless @verbose
    return if !@last_repaint.nil? && (Time.now - @last_repaint < 0.1) && !force

    msg = ""

    if @banner.nil? && respond_to?(:interfaces_group) && interfaces_group.present?
      @banner = interfaces_group.banner status_width
      status_height
      @_status_height -= @banner.lines.count + 2
    end

    if @banner.present?
      msg += @banner
      msg += new_line + "-"*term_width + new_line
    end

    full_status = @statuses || ""
    full_status = full_status.last(status_width*10) || ""
    padding_size = [(number_of_lines - @current_line - 1), (status_width - full_status.size/10)].min
    full_status = "#{full_status}#{"."*[padding_size, 0].max}"

    msg += "#{"%#{padding}d" % (@current_line + 1)}/#{number_of_lines}: #{full_status}"

    lines_count = [(status_height / 2) - 3, 1].max

    if @messages.any?
      msg += new_line(2)
      msg += colorize "=== MESSAGES (#{@messages.count}) ===#{new_line}", :green
      msg += "[...]#{new_line}" if @messages.count > lines_count
      msg += @messages.last(lines_count).map do |m|
        "[#{"%.5f" % m[0]}]\t" + m[1].truncate(status_width - 10)
      end.join(new_line)
      msg += new_line*[lines_count-@messages.count, 0].max
    end

    if @_errors.any?
      msg += new_line(2)
      msg += colorize "=== ERRORS (#{@_errors.count}) ===#{new_line}", :red
      msg += "[...]#{new_line}" if @_errors.count > lines_count
      msg += @_errors.last(lines_count).map do |j|
        kind = j[:kind]
        kind = colorize(kind, kind == :error ? :red : :orange)
        kind = "[#{kind}]"
        kind += " "*[0, (25 - j[:kind].size)].max
        line = kind
        line << "L#{j[:line]}\t" if j[:line]
        line << "#{j[:error]}\t\t" if j[:error]
        line << "#{j[:message]}" if j[:message]
        encode_string(line).truncate(status_width)
      end.join(new_line)
    end
    custom_print msg, clear: true
    @last_repaint = Time.now
  end

  def full_state
    msg = ""
    full_width = 150

    if @banner.present?
      msg += @banner
      msg += @output == :html ? "<hr>" : new_line + "-"*term_width + new_line
    end

    return msg if @status == :success

    if @messages.any?
      msg += new_line(2)
      msg += colorize "=== MESSAGES (#{@messages.count}) ===#{new_line}", :green
      msg += @messages.map do |m|
        "[#{"%.5f" % m[0]}]\t" + m[1].truncate(full_width - 10)
      end.join(new_line)
    end

    if @_errors.any?
      msg += new_line(2)
      msg += colorize "=== ERRORS (#{@_errors.count}) ===#{new_line}", :red
      msg += @_errors.map do |j|
        kind = j[:kind]
        colorized_kind = colorize(kind, kind == :error ? :red : :orange)
        colorized_kind = "[#{kind}]"
        colorized_kind += " "*(25 - kind.size)
        line = colorized_kind
        line << "L#{j[:line]}\t" if j[:line]
        line << "#{j[:error]}\t\t" if j[:error]
        line << "#{j[:message]}" if j[:message]
        html_tags_size = 0
        html_tags_size += j[:error].scan(/<.*?>/).map(&:size).sum if j[:error]
        html_tags_size += j[:message].scan(/<.*?>/).map(&:size).sum if j[:message]
        encode_string(line).truncate(full_width + html_tags_size)
      end.join(new_line)
    end
    msg += new_line(2)
    msg
  end

  def custom_print msg, opts={}
    return unless @verbose
    out = ""
    msg = colorize(msg, opts[:color]) if opts[:color]
    puts "\e[H\e[2J" if opts[:clear] && @output == :console
    out += msg
    print out
  end
end
