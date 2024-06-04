# Preview all emails at http://localhost:3000/rails/mailers/publication_mailer
class PublicationMailerPreview < ActionMailer::Preview

  def publish
    dest = Destination::Mail.new(publication_setup_id: 1, name: 'test destination', recipients: ["test@test.com"], email_title: "Publication par Mail", email_text: "Bonjour", attached_export_file: false)
    PublicationMailer.publish(Publication.first, dest)
  end

  def finished
    dest = Destination::Mail.new(publication_setup_id: 1, name: 'test destination', recipients: ["test@test.com"], email_title: "Publication par Mail", email_text: "Bonjour", attached_export_file: true)
    PublicationMailer.finished(Publication.first.id, dest)
  end

end