class ApplicationPolicy

  attr_reader :current_referential, :record, :user
  def initialize(user_context, record)
    @user                = user_context.user
    @current_referential = user_context.context[:referential]
    @record              = record
  end

  # HMMM: Maybe one can tie index? to show? again by replacing record.class as follows:
  #       Class === record ? record : record.class
  def scope
    Pundit.policy_scope!(user, record.class)
  end

  # Make authorization by action easier
  def delete?
    destroy?
  end

  def authorizes_action?(action)
    public_send("#{action}?")
  rescue NoMethodError
    false
  end


  #
  # Tied permissions
  # ----------------

  # Tie edit? and update? together, #edit?, do not override #edit?,
  # unless you want to break this tie on purpose
  def edit?
    update?
  end

  # Tie new? and create? together, do not override #new?,
  # unless you want to break this tie on purpose
  def new?
    create?
  end


  #
  # Permissions for undestructive actions
  # -------------------------------------

  def index?
    true
  end

  def show?
    scope.where(:id => record.id).exists?
  end


  #
  # Permissions for destructive actions
  # -----------------------------------

  def create?
    false
  end

  def destroy?
    false
  end

  def update?
    false
  end


  #
  #  Custom Permissions
  #  ------------------

  def archived?
    return @is_archived if instance_variable_defined?(:@is_archived)
    @is_archived = is_archived
  end

  def referential_read_only?
    return @is_referential_read_only if instance_variable_defined?(:@is_referential_read_only)
    @is_referential_read_only = is_referential_read_only
  end

  def organisation_match?
    user.organisation_id == organisation_id
  end

  def organisation_id
    # When sending permission to react UI, we don't have access to record object for edit & destroy.. actions
    referential.try(:organisation_id) || record.try(:organisation_id)
  end

  #
  #  Helpers
  #  -------

  def referential
    @referential ||=  record.is_a?(Referential) && record || current_referential || record_referential
  end

  def record_referential
    record.referential if record.respond_to?(:referential)
  end
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      scope
    end
  end

  private
  def is_archived
    !!case referential
    when Referential
      referential.archived_at
    else
      current_referential.try(:archived_at)
    end
  end

  def is_referential_read_only
    !!case referential
    when Referential
      referential.referential_read_only?
    else
      current_referential.try(:referential_read_only?)
    end
  end
end
