module ColorSupport
  extend ActiveSupport::Concern

  included do
    extend Enumerize
    enumerize :color, in: %w(#9B9B9B #FFA070 #C67300 #7F551B #41CCE3 #09B09C #3655D7 #6321A0 #E796C6 #DD2DAA)

    def color
      _color = read_attribute(:color)
      _color.present? ? _color : nil
    end
  end

  module ClassMethods

    def colors_i18n
      Hash[*color.values.map{|c| [I18n.t("enumerize.color.#{c[1..-1]}"), c]}.flatten]
    end
  end

end