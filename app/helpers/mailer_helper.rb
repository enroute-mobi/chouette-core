# frozen_string_literal: true

module MailerHelper
  def mailer_link_to(text, url, opts = {}, &block)
    link_to text, url, opts.update({ class: 'mail-body-link' }), &block
  end

  def mailer_footer_link_to(text, url, opts = {}, &block)
    link_to text, url, opts.update({ class: 'mail-footer-link' }), &block
  end

  def mailer_button(text, url, opts = {})
    link_to text, url, opts.update({ class: 'mail-button' })
  end

  def render_custom(name)
    path = File.join(
      Rails.root,
      'app',
      'views',
      'layouts',
      'mailer',
      'custom',
      "_#{name}.html.*"
    )
    if !Dir.glob(path).empty?
      render partial: "layouts/mailer/custom/#{name}"
    else
      render partial: "layouts/mailer/#{name}"
    end
  end

  def mail_footer
    render_custom :footer
  end

  def mail_header
    render_custom :header
  end

  def subject_prefix
    Chouette::Config.mailer.subject_prefix
  end

  def mail_subject(i18n: nil, method: 'finished', attributes: {})
    i18n ||= "mailers.#{self.class.name.underscore}.#{method}.subject"
    if @status
      operation_status ||= "mailers.statuses.#{@status}"
      [subject_prefix, translate(i18n, attributes), '(' + translate(operation_status) + ')'].compact.join(' ')
    else
      [subject_prefix, translate(i18n, attributes)].compact.join(' ')
    end
  end
end
