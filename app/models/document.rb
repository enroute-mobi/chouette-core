class Document < ApplicationModel
	include CodeSupport

	belongs_to :document_type, required: true
	belongs_to :document_provider, required: true

	has_many :codes, as: :resource, dependent: :delete_all

	validates_associated :codes

	validates :name, :file, :document_type_id, :document_provider_id, :validity_period, presence: true
	validate :has_valid_validity_period

	mount_uploader :file, DocumentUploader

	def self.file_extension_whitelist
		%w(pdf kml jpg jpeg png)
	end

	def valid_after
		validity_period&.begin
	end

	def valid_until
		validity_period&.end
	end

	private

	def has_valid_validity_period
		errors.add(:validity_period, :no_bounds) unless valid_after.is_a?(Date) || valid_until.is_a?(Date)

		if (valid_after.is_a?(Date) && valid_until.is_a?(Date)) && (valid_until < valid_after)
			errors.add(:validity_period, :after_before_begin)
		end
	end
end

