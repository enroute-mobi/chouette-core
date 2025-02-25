module Chouette::ChecksumManager
  class SerializedObject
    def self.new object, opts={}
      return object if object.is_a?(SerializedObject)
      super object, opts
    end

    def initialize original_object, opts={}
      @serialized_object = serialize_object(original_object)
      if original_object.is_a?(ActiveRecord::Base)
        # in case we have a new AR::Base, we store it already
        # this prevent errors if the object is not persisted yet
        @object = original_object unless original_object.persisted? && !opts[:load_object]
        @need_save = false
      else
        @need_save = true
      end
      @need_save = opts[:need_save] if opts.key?(:need_save)
    end

    def signature opts={}
      unserialized = object&.to_s
      return unserialized if opts[:unserialized]
      @signature ||= (@serialized_object.last.present? ? @serialized_object.join('_') : unserialized)
    end

    def reload
      @object&.reload
    end

    def need_save
      @need_save
    end

    def serialized_object
      @serialized_object
    end

    def object
      @object ||= resolve_object @serialized_object
    end

    def resolve_object object
      return object if object.is_a? ActiveRecord::Base
      begin
        object.first.constantize.find(object.last)
      rescue => e
        Chouette::Safe.capture "SerializedObject unable to resolve object #{object.inspect}", e
        raise
      end
    end

    def serialize_object object
      return [object.class.name, object.id] if object.is_a? ActiveRecord::Base
      object
    end
  end
end
