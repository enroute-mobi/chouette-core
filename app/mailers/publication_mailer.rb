class PublicationMailer < ApplicationMailer
  def publish(publication, destination_mail)
    @destination_mail = destination_mail
    @publication = publication

    @publication_api = PublicationApi.find(@destination_mail.link_to_api) if @destination_mail.link_to_api.present?

    # Select only related exports that contains a file
    used_exports = publication.exports.select{|e| e[:file]}

    # If there are more than one exported file per publication, the generated export files won't be attached to the mail
    # If the file size exceeds 10 mb, the file won't be attached as well
    if @destination_mail.attached_export_file && used_exports.count == 1 && (used_exports.first.file.size.to_f / 1024000 < 10)
      filename = @destination_mail.attached_export_filename.presence || File.basename(used_exports.first.file.path)
      attachments[filename] = used_exports.first.file.read
    end

    mail bcc: destination_mail.recipients, subject: @destination_mail.email_title
  end

  def finished(publication_id, recipient, status=nil)
    @publication = Publication.find(publication_id)
    @status = status || @publication.status
    mail to: recipient, subject: mail_subject
  end
end
