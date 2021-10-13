if ::Destination.enabled?("mail")
  class Destination::Mail < ::Destination

    before_validation do
      self.email_title = ActionController::Base.helpers.strip_tags(self.email_title)
      self.email_text = ActionController::Base.helpers.strip_tags(self.email_text)
      self.recipients = self.recipients.delete_if {|r| r.empty? }
    end

    option :email_title, serialize:  ActiveRecord::Type::String
    validates :email_title, presence: true, length: { maximum: 100 }

    option :email_text, type: :text, serialize:  ActiveRecord::Type::String
    validates :email_text, presence: true, length: { maximum: 1024 }

    option :recipients, type: :array, default_value: []
    validates :recipients, presence: true
    validate :check_mail_array

    option :link_to_api, collection: ->(){publication_setup.workgroup.publication_apis.map{|pbl| [pbl.name, pbl.id]}}, allow_blank: true

    option :attached_export_file, type: :boolean, default_value: false

    option :attached_export_filename
    validates :attached_export_filename, format: { with: /\A[a-z0-9-]+\z/i, message: :filename, allow_blank: true }

    def do_transmit(publication, _report)
      PublicationMailer.publish(publication, self).deliver_later
    end

    def check_mail_array
      wrong_ones = recipients.select{|r| !r.match(Devise::email_regexp)}
      errors.add(:recipients,  I18n.t('destinations.errors.mail.recipients_mail_syntax', emails: wrong_ones.join(", "))) if wrong_ones.any?
    end

  end
end
