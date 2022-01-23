module Macro
  class CreateCode < Base
    # Use enumerize directly
    enumerize :target_model, in: %w{StopArea Line VehicleJourney}

    option :target_model, collection: target_model.values, required: true
    option :source_attribute, required: true # TODO use ModelAttribute ?
    option :source_pattern
    option :target_code_space, required: true # TODO must be id or short_name of one of Workgroup CodeSpaces
    option :target_pattern

    # Use standard Rails validation methods
    validates :target_model, :source_attribute, :target_code_space, presence: true

    class Run < Macro::Base::Run
      # TODO copy options from Macro::CreateCode class
      option :target_model, required: true
      option :source_attribute, required: true
      option :source_pattern
      option :target_code_space, required: true
      option :target_pattern

      def run
        # This Updater pattern made simple to test
        #
        # Could be optimize with a more complex logic:
        # - read all source value (with cursor)
        # - compute all target value
        # - create all required codes with inserter ?
        models_without_code.find_each do |model|
          code_value = target.value(source.value(model))
          Rails.logger.debug { "Create code '#{code_value}' for #{model.class}##{model.id}" }
          model.codes.create! code_space: code_space, value: code_value
        end
      end

      def source
        @source ||= Source.new(
          workgroup: workgroup,
          attribute: source_attribute,
          pattern: source_pattern,
        )
      end

      def target
        @target ||= Target.new(pattern: target_pattern)
      end

      def code_space
        @code_space ||= workgroup.code_spaces.find_by(short_name: target_code_space)
      end

      def model_collection
        target_model.underscore.pluralize
      end

      def models
        @models ||= context.send(model_collection)
      end

      def models_without_code
        # FIXME
        #
        # models.left_joins(:codes).where(codes: { id: nil }))
        # works
        #
        # models.left_joins(:codes).where(codes: { code_space: code_space }))
        # works
        #
        # models.left_joins(:codes).where(codes: { code_space: code_space, id: nil }))
        # doesn't work
        models.where.not(id: models.joins(:codes).where(codes: { code_space: code_space }))
      end

      def context
        referential || workbench
      end
    end

    class Source
      attr_accessor :workgroup, :attribute, :pattern
      def initialize(attributes = {})
        attributes.each { |k,v| send "#{k}=", v }
      end

      def value(model)
        apply_pattern raw_value(model)
      end

      def raw_value(model)
        unless code_space
          model.send attribute
        else
          model.codes.find_by(code_space: code_space).value
        end
      end

      def apply_pattern(value)
        if pattern_regexp && pattern_regexp =~ value
          $1
        else
          value
        end
      end

      def pattern_regexp
        @pattern_regexp ||= Regexp.new(pattern) if pattern.present?
      end

      def code_space_short_name
        if /^code:(.*)/ =~ attribute
          $1
        end
      end

      def code_space
        return unless workgroup
        @code_space ||= workgroup.code_spaces.find_by(short_name: code_space_short_name)
      end
    end

    class Target
      attr_accessor :pattern
      def initialize(attributes = {})
        attributes.each { |k,v| send "#{k}=", v }
      end

      def value(value)
        apply_pattern value
      end

      def has_pattern?
        pattern.present?
      end

      def apply_pattern(value)
        return value unless has_pattern?

        value = value_substitution.call(value)
        pattern.gsub(/%{value[^}]*}/, value)
      end

      def value_substitution
        if has_pattern? && %r@%{value//([^/]+)/([^}*])}@ =~ pattern
          Proc.new { |value| value.gsub($1, $2) }
        else
          Proc.new { |value| value }
        end
      end
    end

  end
end
