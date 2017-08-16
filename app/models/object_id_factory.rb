class ObjectIdFactory < ActiveRecord::Base

  class << self
    def for( model_class, prefix: nil )
      prefix ||= model_class.to_s
      loop do
        find_unique_value(model_class, prefix).tap do | instance |
          return instance.prefixed_name(prefix) if instance
        end
      end
    end

    private
    def find_unique_value(model_class, prefix)
      myself = create
      myself.exists?(model_class, prefix) ? nil : myself
    end
  end

  def exists?(model_class, prefix)
    model_class.exists?(objectid: prefixed_name(prefix))
  end

  def prefixed_name(prefix)
    [prefix, id].join("_")
  end


end
