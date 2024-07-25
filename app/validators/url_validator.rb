class UrlValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.blank?

    url = URL.new(value)

    if options[:scheme] && !url.valid_scheme?(options[:scheme])
      record.errors.add(attribute, :invalid_scheme, expected_schemes: Array(options[:scheme]).to_sentence)
    end

    unless url.resolved_host?
      record.errors.add(attribute, :host_not_found)
    else
      if options[:host] && !url.valid_host?(options[:host])
        record.errors.add(attribute, :host_not_allowed, expected_host: options[:host])
      end

      if options[:private_host] == false && !url.public_host?
        record.errors.add(attribute, :private_host_not_allowed)
      end
    end
  rescue URI::InvalidURIError
    record.errors.add(attribute, :invalid)
  end

  class URL < SimpleDelegator

    def initialize(value)
      super URI.parse(value)
    end

    def valid_scheme?(values)
      Array(values).include?(scheme)
    end

    def valid_host?(value)
      case value
      when String
        host == value
      else
        host =~ value
      end
    end

    def cached_resolved_host
      @cached_resolved_host ||=
        begin
          Resolv.getaddress(host)
        rescue Resolv::ResolvError
          :none
        end
    end

    def resolved_host
      [ :none, '0.0.0.0' ].include?(cached_resolved_host) ? nil : cached_resolved_host
    end

    def resolved_host?
      resolved_host.present?
    end

    def ip_address
      return nil unless resolved_host?
      @ip_address ||= IPAddr.new(resolved_host)
    end

    def public_host?
      return false unless ip_address

      # Ex: 127.0.0.1 or ::1
      return false if ip_address.loopback?

      # IPv4 addresses in 10.0.0.0/8, 172.16.0.0/12 and 192.168.0.0/16 as defined in RFC 1918
      # and IPv6 Unique Local Addresses in fc00::/7 as defined in RFC 4193 are considered private.
      return false if ip_address.private?

      # IPv4 addresses in 169.254.0.0/16 reserved by RFC 3927
      # and Link-Local IPv6 Unicast Addresses in fe80::/10 reserved by RFC 4291 are considered link-local.
      return false if ip_address.link_local?

      true
    end

  end
end
