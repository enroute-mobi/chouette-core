class UserDeliverInterceptor

  def initialize(enabled: false, whitelist: nil, blacklist: nil)
    @enabled, @whitelist, @blacklist = enabled, whitelist, blacklist

    @whitelist ||= []
    @blacklist ||= []
  end

  attr_accessor :enabled, :blacklist, :whitelist

  def delivering_email(message)
    cancel(message) unless accept?(message)
  end

  def enabled?
    @enabled
  end

  def accept?(message)
    return false unless enabled?

    message_recipients(message).all? do |email_address|
      accept_email_address?(email_address)
    end
  end

  def message_recipients(message)
    (Array(message.to) + Array(message.bcc)).uniq
  end

  def accept_email_address?(email_address)
    !blacklisted?(email_address) && whitelisted?(email_address)
  end

  def cancel(message)
    message.perform_deliveries = false
    Rails.logger.info "Canceled email to #{message.to}"
  end

  def whitelisted?(email_address)
    return true if whitelist.empty?
    self.class.match? whitelist, email_address
  end

  def blacklisted?(email_address)
    self.class.match? blacklist, email_address
  end

  DOMAIN_DEFINITION = "@"

  def self.match?(definition, email_address)
    case definition
    when Array
      definition.any? { |d| match? d, email_address }
    when Regexp
      definition.match? email_address
    when String
      if definition.start_with?(DOMAIN_DEFINITION)
        email_address.end_with? definition
      else
        definition == email_address
      end
    else
      false
    end
  end

  def self.from_config(config = Rails.application.config)
    unless config.try(:chouette_email_user)
      return UserDeliverInterceptor.new enabled: false
    end

    UserDeliverInterceptor.new enabled: true,
                               blacklist: config.try(:chouette_email_blacklist),
                               whitelist: config.try(:chouette_email_whitelist)
  end

end
