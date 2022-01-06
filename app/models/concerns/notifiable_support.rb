module NotifiableSupport
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :notification_target, in: %w[none user workbench], default: :none
    belongs_to :user
  end

  class_methods do
    def notification_target_options
      notification_target.values.map { |k| [k && "enumerize.notification_target.#{k}".t, k] }
    end
  end

  def notification_recipients
    case notification_target.to_s
    when 'user'
      [ user&.email ].compact
    when 'workbench'
      workbench.users.pluck(:email)
    else
      []
    end
  end
end
