module CodeSupport
  extend ActiveSupport::Concern

  included do
    has_many :codes, as: :resource, dependent: :delete_all
    accepts_nested_attributes_for :codes, allow_destroy: true, reject_if: :all_blank
    validates_associated :codes

    scope :by_code, ->(code_space, value) { joins(:codes).where(codes: { code_space: code_space, value: value }) }
    scope :without_code, ->(code_space) { where.not(id: joins(:codes).where(codes: { code_space_id: code_space })) }

    #
    # provider.stop_areas.first_or_initialize_by_code code_space, "A"
    # 
    def self.first_or_initialize_by_code(code_space, value)
      by_code(code_space, value).first_or_initialize do |model|
        model.codes = [Code.new(code_space: code_space, value: value)]
        yield model if block_given?
      end
    end

    #
    # provider.stop_areas.first_or_create_by_code code_space, "A"
    # 
    def self.first_or_create_by_code(code_space, value)
      by_code(code_space, value).first_or_create do |model|
        model.codes = [Code.new(code_space: code_space, value: value)]
        yield model if block_given?
      end
    end
  end
end
