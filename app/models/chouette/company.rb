module Chouette
  module WorkgroupFromClass
    def workgroup
      self.class.current_workgroup || super
    end
  end

  class Company < Chouette::ActiveRecord
    before_validation :define_line_referential, on: :create

    has_metadata

    prepend WorkgroupFromClass

    include LineReferentialSupport
    include ObjectidSupport
    include CustomFieldsSupport

    belongs_to :line_provider, required: true

    has_many :lines, dependent: :nullify
    has_many :control_messages, as: :source, class_name: "::Control::Message", foreign_key: :source_id

    # validates_format_of :registration_number, :with => %r{\A[0-9A-Za-z_-]+\Z}, :allow_nil => true, :allow_blank => true
    validates_presence_of :name
    validates :registration_number, uniqueness: { scope: :line_provider_id }, allow_blank: true

    # Cf. #8132
    # validates_format_of :url, :with => %r{\Ahttps?:\/\/([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?\Z}, :allow_nil => true, :allow_blank => true

    scope :by_provider, ->(line_provider) { where(line_provider_id: line_provider.id) }
    scope :by_text, ->(text) { text.blank? ? all : where('lower(companies.name) LIKE :t or lower(companies.short_name) LIKE :t or lower(companies.objectid) LIKE :t', t: "%#{text.downcase}%") }

    def self.nullable_attributes
      [:default_contact_organizational_unit, :default_contact_operating_department_name, :code, :default_contact_phone, :default_contact_fax, :default_contact_email, :default_contact_url, :time_zone]
    end

    def has_private_contact?
      %w(private_contact).product(%w(name email phone url)).any?{ |k| send(k.join('_')).present? }
    end

    def has_customer_service_contact?
      %w(customer_service_contact).product(%w(name email phone url)).any?{ |k| send(k.join('_')).present? }
    end

    def full_display_name
      [self.get_objectid.short_id, name].join(' - ')
    end

    def display_name
      full_display_name.truncate(50)
    end

    def country
      return unless country_code
      ISO3166::Country[country_code]
    end

    def country_name
      return unless country
      country.translations[I18n.locale.to_s] || country.name
    end

    private

    def define_line_referential
      # TODO Improve performance ?
      self.line_referential ||= line_provider&.line_referential
    end
  end
end
