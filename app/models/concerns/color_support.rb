module ColorSupport
  extend ActiveSupport::Concern

  included do
    extend Enumerize
  end

  module ClassMethods

    def color_attribute name=:color, colors=nil
      colors ||= %w(9B9B9B FFA070 C67300 7F551B 41CCE3 09B09C 3655D7 6321A0 E796C6 DD2DAA)

      plural = name.to_s.pluralize

      define_method name do
        _color = read_attribute(name.to_sym)
        _color.present? ? _color : nil
      end

      enumerize name, in: colors

      define_singleton_method "#{plural}_i18n" do
        Hash[*send(name).values.map{|c| [I18n.t("enumerize.#{name}.#{c}"), c]}.flatten]
      end
    end

    def open_color_attribute name=:color
      validates_format_of name, with: %r{\A[\dA-F]{6}\Z}, allow_nil: true, allow_blank: true

      define_method name do
        _color = read_attribute(name.to_sym)
        _color.present? ? _color : nil
      end

      define_method "#{name}_hex" do
        _color = read_attribute(name.to_sym)
        _color.present? ? "##{_color}" : nil
      end

    end
  end

end
