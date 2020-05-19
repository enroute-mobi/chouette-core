if ::Destination.enabled?("mail")
  class Destination::Mail < ::Destination

    option :email_title, required: true, max_length: 100, before_save: ->(){ self.email_title = ActionController::Base.helpers.strip_tags(self.email_title) }
    option :email_text, type: :text, required: true, max_length: 1024, before_save: ->(){ self.email_text = ActionController::Base.helpers.strip_tags(self.email_text) }
    option :recipients, required: true, validates: {with: Devise.email_regexp, message: :mail_format}
    option :link_to_api, collection: ->(){publication_setup.workgroup.publication_apis.map{|pbl| [pbl.name, pbl.id]}}
    option :attached_export_file, type: :boolean, default_value: false
    option :attached_export_filename, validates: { with: /\A[a-z0-9-]+\z/i, message: :filename, allow_blank: true }

    def do_transmit(publication, report)
      puts "Send mail to recipents !"
    end
  end
end
