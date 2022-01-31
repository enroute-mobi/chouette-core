module ObjectidSupport
  extend ActiveSupport::Concern

  included do
    before_validation :before_validation_objectid, unless: Proc.new {|model| model.read_attribute(:objectid)}
    after_commit :after_commit_objectid, on: :create, if: Proc.new {|model| model.read_attribute(:objectid).try(:include?, '__pending_id__')}
    validates_presence_of :objectid
    validates_uniqueness_of :objectid, unless: Proc.new {|model| model.read_attribute(:objectid).nil? || model.class.skip_objectid_uniqueness? }

    scope :with_short_id, ->(q){
      return self.none unless self.exists?
      referential = self&.last&.referential
      self.all.merge referential.objectid_formatter.with_short_id(self, q)
    }

    ransacker :short_id do |parent|
      referential = self&.last&.referential
      referential.present? ? Arel.sql(referential.objectid_formatter.short_id_sql_expr(self)) : Arel.sql('objectid')
    end

    class << self

      def skip_objectid_uniqueness?
        ApplicationModel.skip_objectid_uniqueness? || @skip_objectid_uniqueness
      end

      def skipping_objectid_uniqueness
        begin
          @skip_objectid_uniqueness = true
          yield
        ensure
          @skip_objectid_uniqueness = false
        end
      end

      def ransackable_scopes(auth_object = nil)
        [:with_short_id]
      end

      def reset_objectid_format_cache!
        @_objectid_format_cache = nil
      end

      def has_objectid_format? referential_class, referential_find
        @_objectid_format_cache ||= SmartCache::Sized.new
        cache_key = { referential_class.name => referential_find }
        @_objectid_format_cache.fetch cache_key do
          referential = referential_class.find_by referential_find
          referential.objectid_format.present?
        end
      end
    end

    mattr_accessor :default_objectid_formatter, default: Chouette::ObjectidFormatter::Netex.new

    def objectid_formatter
      if referential_identifier.blank?
        @objectid_formatter ||= default_objectid_formatter
      else
        Chouette::ObjectidFormatter.for_objectid_provider(*referential_identifier)
      end
    end

    def referential_identifier
      %w[line_referential stop_area_referential].each do |name|
        if (r = self.class.reflections[name])
          id  = send(r.foreign_key)
          return id  ? [r.klass, { id: id }] : nil
        end
      end
      referential_slug ? [Referential, { slug: referential_slug }] : nil
    end

    def before_validation_objectid
      objectid_formatter.before_validation self
    end

    def after_commit_objectid
      objectid_formatter.after_commit self
    end

    def get_objectid
      identifier = referential_identifier
      objectid_formatter.get_objectid read_attribute(:objectid) if identifier.present? && self.class.has_objectid_format?(*identifier) && read_attribute(:objectid)
    end

    def objectid
      get_objectid.try(:to_s)
    end

    def objectid_class
      get_objectid.try(:class)
    end

    def raw_objectid
      read_attribute(:objectid)
    end

  end
end
