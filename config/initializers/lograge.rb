# frozen_string_literal: true

Rails.application.configure do
  config.lograge.enabled = true

  config.lograge.ignore_actions = [
    'NotificationsController#index',
    'HealthCheck::HealthCheckController#index'
  ]
  config.colorize_logging = false

  config.lograge.custom_payload do |controller|
    Lograge::CustomPayload.new(controller).payload
  end

  config.lograge.formatter = Lograge::Formatters::Json.new
end

module Lograge
  # Use to customize lograge payload
  class CustomPayload < Struct.new(:controller)
    def current(name)
      method = "current_#{name}"
      controller.send(method)&.id
    rescue NoMethodError, ActiveRecord::RecordNotFound
      nil
    end

    def user
      current :user
    end

    def workbench
      current :workbench
    end

    def workgroup
      current :workgroup
    end

    def referential
      current :referential
    end

    def locale
      I18n.locale
    end

    def payload
      {}.tap do |payload|
        %i[user workbench workgroup locale].each do |attribute|
          value = send attribute
          payload[attribute] = value if value
        end
      end
    end
  end
end
