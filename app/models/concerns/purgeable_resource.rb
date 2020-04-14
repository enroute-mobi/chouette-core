module PurgeableResource
  extend ActiveSupport::Concern

  DEFAULT_CLEAN_FILES_AFTER = 60
  DEFAULT_CLEAN_AFTER = 90

  included do
    scope :file_purgeable, -> { where("created_at <= ?", clean_files_after.days.ago) }
    scope :purgeable, -> { where("created_at <= ?", clean_after.days.ago) }
  end

  module ClassMethods
    def clean_files_after=(value)
      @clean_files_after = value
    end

    def clean_files_after
      @clean_files_after || DEFAULT_CLEAN_FILES_AFTER
    end

    def clean_after=(value)
      @clean_after = value
    end

    def clean_after
      @clean_after || DEFAULT_CLEAN_AFTER
    end
  end
end
