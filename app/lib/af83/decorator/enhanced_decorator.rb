module AF83::Decorator::EnhancedDecorator
  module ClassMethods
    def action_link args={}
      raise "You are using `action_link` inside a with_instance_decorator block, but not on the instance decorator itself.\n Use `instance_decorator.action_link` or move outside of the block, as this may lead to an unforeseen behaviour." if @_with_instance_decorator
      args[:if] = @_condition if args[:if].nil?

      options, link_options = parse_options args

      link = AF83::Decorator::Link.new(link_options)
      instance_exec(link, &options[:before_block]) if options[:before_block]
      yield link if block_given?
      raise AF83::Decorator::IncompleteLinkDefinition.new(link.errors) unless link.complete?
      weight = options[:weight] || 1
      @_action_links ||= []
      @_action_links[weight] ||= []
      @_action_links[weight] << link
    end

    ### Here we define some shortcuts that match dthe default behaviours

    def crud
      show_action_link
      edit_action_link
      destroy_action_link
    end

    def create_action_link args={}, &block
      opts = {
        on: :index,
        primary: :index,
        policy: :create,
        before_block: -> (l){
          l.content { object.klass.t_action(:new) }
          l.icon :plus
          l.href    { [:new, scope, object.klass.model_name.singular_route_key.to_sym ] }
        }
      }
      action_link opts.update(args), &block
    end

    def show_action_link args={}, &block
      opts = {
        on: :index,
        primary: :index,
        before_block: -> (l){
          l.content { object.class.t_action(:show) }
          l.href { [scope, object] }
          l.icon :eye
        }
      }
      action_link opts.update(args), &block
    end

    def edit_action_link args={}, &block
      opts = {
        primary: %i(show index),
        policy: :edit,
        before_block: -> (l){
          l.content { object.class.t_action(:edit) }
          l.href { [:edit, scope, object] }
          l.icon :"pencil-alt"
        }
      }
      action_link opts.update(args), &block
    end

    def destroy_action_link args={}, &block
      opts = {
        policy: :destroy,
        footer: true,
        secondary: :show,
        before_block: -> (l){
          l.content { object.class.t_action(:destroy) }
          l.href { [scope, object] }
          l.method :delete
          l.data {{ confirm: object.class.t_action(:destroy_confirm) }}
          l.icon :trash
          l.icon_class :danger
        }
      }
      action_link opts.update(args), &block
    end

    def set_scope value=nil, &block
      @scope = value || block
    end

    def scope
      @scope
    end

    def inspect
      "#{name} #{@_action_links.inspect}"
    end

    def t key
      eval  "-> (l){ h.t('#{key}') }"
    end

    def with_condition condition, &block
      @_condition = condition
      instance_eval &block
      @_condition = nil
    end

    def action_links action
      (@_action_links || []).flatten.compact.select{|l| l.for_action?(action)}
    end

    def parse_options args
      options = {}
      %i(weight primary secondary footer on action actions policy feature if groups group before_block).each do |k|
        options[k] = args.delete(k) if args.has_key?(k)
      end
      link_options = args.dup

      actions = options.delete :actions
      actions ||= options.delete :on
      actions ||= [options.delete(:action)]
      actions = [actions] unless actions.is_a?(Array)
      link_options[:_actions] = actions.compact

      link_options[:_groups] = options.delete(:groups)
      link_options[:_groups] ||= {}
      if single_group = options.delete(:group)
        if(single_group.is_a?(Symbol) || single_group.is_a?(String))
          link_options[:_groups][single_group] = true
        else
          link_options[:_groups].update single_group
        end
      end
      link_options[:_groups][:primary] ||= options.delete :primary
      link_options[:_groups][:secondary] ||= options.delete :secondary
      link_options[:_groups][:footer] ||= options.delete :footer

      link_options[:_if] = options.delete(:if)
      link_options[:_policy] = options.delete(:policy)
      link_options[:_feature] = options.delete(:feature)

      [options, link_options]
    end
  end

  def action_links action=:index, opts={}
    @action = action&.to_sym
    links = AF83::Decorator::ActionLinks.new links: self.class.action_links(action), context: self, action: action
    group = opts[:group]
    links = links.for_group opts[:group]
    links
  end

  def primary_links action=:index
    action_links(action, group: :primary)
  end

  def secondary_links action=:index
    action_links(action, group: :secondary)
  end

  # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
  def check_policy(action, resource_class = nil, **options)
    if resource_class
      policy_object = options[:object] || object
      policy_args = [resource_class]
    elsif !on_instance?
      policy_object = policy_parent
      policy_args = [object.klass]
    elsif action.to_s == 'create'
      policy_object = policy_parent
      policy_args = object.class
    else
      policy_object = options[:object] || object
      policy_args = []
    end

    policy_instance = h.policy(policy_object)
    Rails.logger.debug do
      "Check policy with #{policy_instance.class} for #{policy_object.class} #{action}? #{policy_args.join(', ')}"
    end

    method = "#{action}?"
    policy_instance.send(method, *policy_args)
  end
  # rubocop:enable Metrics/AbcSize,Metrics/MethodLength

  def check_feature feature
    h.has_feature? feature
  end

  def scope
    scope = self.class.scope
    scope = instance_exec &scope if scope.is_a? Proc
    scope
  end

  def policy_parent
    return @policy_parent if @policy_parent

    elements = Array(scope)
    last_record_index = elements.rindex { |s| s.is_a?(ActiveRecord::Base) }
    @policy_parent = if last_record_index
                       elements[(last_record_index + 1)..].inject(elements[last_record_index], &:send)
                     else
                       h.current_user
                     end
  end

  def on_instance?
    false
  end
end
