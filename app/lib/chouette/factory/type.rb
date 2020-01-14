module Chouette
  class Factory
    class Type

      attr_accessor :name
      def initialize(name)
        @name = name
      end

      alias to_s name

      def sub_types
        @sub_types ||= {}
      end

      def assign_sub_types(types)
        types.each do |type|
          sub_types[type.name] = type
        end
      end

      def find(name)
        if sub_type = sub_types[name]
          return [sub_type]
        else
          sub_types.each do |_, type|
            path = type.find name
            return [type, *path] if path
          end
        end

        nil
      end

      def class_model
        return if root?

        @class_model ||=
          begin
            base_class_name = name.to_s.classify
            candidates = ["Chouette::#{base_class_name}", base_class_name]
            candidates.map { |n| n.constantize rescue nil }.compact.first
          end
      end

      def root?
        @name == :root
      end

      def self.root
        @root ||= Type.new(:root).tap do |root|
          root.assign_sub_types create_sub_types(Chouette::Factory::HIERARCHY)
        end
      end

      def self.create_sub_types(hierarchy)
        hierarchy.map do |entries|
          name, children =
                if entries.is_a?(Array)
                  [entries.first, entries.second]
                else
                  [entries, []]
                end

          new(name).tap do |type|
            type.assign_sub_types create_sub_types(children)
          end
        end
      end
    end
  end
end
