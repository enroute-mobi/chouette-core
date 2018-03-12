# -*- coding: utf-8 -*-
# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
ActiveSupport::Inflector.inflections(:fr) do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
  inflect.plural 'réseau', 'réseaux'
  inflect.plural 'Zone de contrainte', 'Zones de contrainte'
end

class String
  def pluralize_with_i18n count=nil, locale=nil
    locale ||= I18n.locale
    pluralize_without_i18n count, locale
  end
  alias_method :pluralize_without_i18n, :pluralize
end
