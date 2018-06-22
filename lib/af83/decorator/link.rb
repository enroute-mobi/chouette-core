class AF83::Decorator::Link
  REQUIRED_ATTRIBUTES = %i(href content)

  attr_reader :context
  attr_reader :action

  def initialize options={}
    @options = {}
    options.each do |k, v|
      send "#{k}", v
    end
  end

  def bind_to_context context, action
    @context = context
    @action = action
    self
  end

  def method *args
    link_method *args
  end

  def class *args
    link_class args
  end

  def method_missing name, *args, &block
    if block_given?
      @options[name] = block
    elsif args.size == 0
      out = @options[name]
      out = context.instance_exec(self, &out) if out.is_a?(Proc)
      out = out.flatten.compact if name.to_s == "href" && out.is_a?(Array)
      out
    else
      # we can use l.foo("bar") or l.foo = "bar"
      if name.to_s =~ /\=$/
        _name = name.to_s.gsub(/=$/, '')
        return send(_name, *args, &block)
      end
      @options[name] = args.first
    end
  end

  def options
    @options.symbolize_keys
  end

  def complete?
    @missing_attributes = REQUIRED_ATTRIBUTES.select{|a| !@options[a].present?}
    @missing_attributes.empty?
  end

  def enabled_actions
    @options[:_actions].map(&:to_s) || []
  end

  def for_action? action=nil
    action ||= @action
    enabled_actions.empty? || enabled_actions.include?(action.to_s)
  end

  def actions_for_group group
    val = @options[:_groups][group]
    val.is_a?(Array) ? val.map(&:to_s) : val
  end

  def in_group_for_action? group
    vals = actions_for_group(group)
    if vals.is_a?(Array)
      return vals.include?(@action.to_s)
    elsif vals.is_a?(String) || vals.is_a?(Symbol)
      vals.to_s == @action.to_s
    else
      !!vals
    end
  end

  def primary?
    in_group_for_action? :primary
  end

  def secondary?
    in_group_for_action? :secondary
  end

  def disabled?
    !!disabled
  end

  def enabled?
    enabled = false
    if @options[:_if].nil?
      enabled = true
    elsif @options[:_if].is_a?(Proc)
      enabled = context.instance_exec(&@options[:_if])
    else
      enabled = !!@options[:_if]
    end

    enabled = enabled && check_policy(@options[:_policy]) if @options[:_policy].present?
    enabled = enabled && check_feature(@options[:_feature]) if @options[:_feature].present?
    enabled
  end

  def check_policy(policy)
    @context.check_policy policy
  end

  def check_feature(feature)
    @context.check_feature feature
  end

  def errors
    "Missing attributes: #{@missing_attributes.to_sentence}"
  end

  def add_class val
    @options[:link_class] ||= []
    @options[:link_class] << val
    @options[:link_class].flatten!
  end

  def extra_class
    (options[:link_class] || []).join(' ')
  end

  def html_options
    out = {}
    options.each do |k, v|
      out[k] = self.send(k) unless k == :content || k == :href || k.to_s =~ /^_/
    end
    out[:method] = link_method
    out[:class] = extra_class
    out.delete(:link_class)
    out.delete(:link_method)
    out[:class] += " disabled" if disabled?
    out[:class].strip!
    out[:disabled] = disabled?
    out
  end

  def to_html
    if block_given?
      link = AF83::Decorator::Link.new(@options).bind_to_context(context, @action)
      yield link
      return link.to_html
    end
    if type&.to_sym == :button
      HTMLElement.new(
        :button,
        content,
        html_options
      ).to_html
    else
      context.h.link_to content, (disabled? ? "#" : href), html_options
    end
  end
end
