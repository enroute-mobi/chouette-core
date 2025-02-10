# frozen_string_literal: true

module SemanticLoggerSupport
  extend ActiveSupport::Concern

  def current_locale
    I18n.locale
  end

  def append_info_to_payload(payload) # rubocop:disable Metrics/MethodLength
    super
    %i[
      locale
      user
      organisation
      workgroup
      workbench
      referential
    ].each do |attribute|
      method_name = :"current_#{attribute}"
      value = send(method_name) if respond_to?(method_name, true)
      if value
        value = value.id if value.respond_to?(:id)
        payload[attribute] = value
      end
    end
  end
end
