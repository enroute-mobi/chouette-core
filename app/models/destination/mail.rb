if ::Destination.enabled?("mail")
  class Destination::Mail < ::Destination

    before_validation do
      self.email_title = ActionController::Base.helpers.strip_tags(self.email_title)
      self.email_text = ActionController::Base.helpers.strip_tags(self.email_text)
    end

    option :email_title
    validates :email_title, presence: true, length: { maximum: 100 }

    option :email_text
    validates :email_text, presence: true, length: { maximum: 1024 }

    option :recipients
    validates :recipients, presence: true, email: true

    option :link_to_api, collection: ->(){publication_setup.workgroup.publication_apis.map{|pbl| [pbl.name, pbl.id]}}

    option :attached_export_file, type: :boolean, default_value: false

    option :attached_export_filename
    validates :attached_export_filename, format: { with: /\A[a-z0-9-]+\z/i, message: :filename, allow_blank: true }

    def do_transmit(publication, report)
      puts "Send mail to recipents !"
    end
  end
end
