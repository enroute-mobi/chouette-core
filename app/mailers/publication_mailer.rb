# frozen_string_literal: true

class PublicationMailer < ApplicationMailer
  def publish(publication, destination_mail)
    @destination_mail = destination_mail
    @publication = publication

    @publication_api = PublicationApi.find(@destination_mail.link_to_api) if @destination_mail.link_to_api.present?

    file = publication.export.try(:file)

    if @destination_mail.attached_export_file && file && (file.size.to_f / 1_024_000 < 10)
      filename = @destination_mail.attached_export_filename.presence || File.basename(file.path)
      attachments[filename] = file.read
    end

    mail bcc: destination_mail.recipients, subject: @destination_mail.email_title
  end

  def finished(publication_id, recipient, status = nil)
    @publication = Publication.find(publication_id)
    @status = status || @publication.status
    mail to: recipient, subject: mail_subject
  end
end
