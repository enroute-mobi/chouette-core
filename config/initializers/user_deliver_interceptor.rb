class UserDeliverInterceptor
  class << self

    def delivering_email(message)
      cancel(message) unless accept?(message)
    end

    def accept?(message)
      true unless (prevent_mails?||test_env?||blacklisted?(message))
    end

    def prevent_mails?
      return unless Rails.application.config.respond_to?(:chouette_email_user)
      !Rails.application.config.chouette_email_user
    end

    def test_env?
      Rails.env.test? || Rails.env.development?
    end

    def blacklisted?(message)
      message.to.any?{|mail| blacklist.any?{|blacklisted_mail| mail.include?(blacklisted_mail)}}
    end

    def blacklist
      Rails.application.config.chouette_email_blacklist
    end

    def cancel(message)
      message.perform_deliveries = false
      Rails.logger.info "Canceled email to #{message.to}"
    end
  end
end

ActionMailer::Base.register_interceptor(UserDeliverInterceptor)
