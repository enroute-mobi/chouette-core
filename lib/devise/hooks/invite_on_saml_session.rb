# frozen_string_literal: true

Warden::Manager.prepend_after_authentication do |record, warden, options|
  if warden.winning_strategy.is_a?(Devise::Strategies::SamlAuthenticatable) && record.invited_to_sign_up?
    scope = options[:scope]

    raw_invitation_token = warden.request.session.delete("#{scope}_invitation_token")
    record_from_invitation_token = record.class.find_by_invitation_token(raw_invitation_token, true)

    if record == record_from_invitation_token
      begin
        old_require_password_on_accepting = record.class.require_password_on_accepting
        record.class.require_password_on_accepting = false
        record.accept_invitation!
      ensure
        record.class.require_password_on_accepting = old_require_password_on_accepting
      end

      throw :warden, scope: scope, message: I18n.t('devise.invitations.invitation_token_invalid') if record.errors.any?
    else
      throw :warden, scope: scope, message: I18n.t('devise.invitations.invitation_token_invalid')
    end
  end
end
