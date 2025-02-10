import { I18n } from 'i18n-js'
import translations from './i18n/translations.json'

const userLocale = document.documentElement.lang

export const i18n = new I18n()

i18n.tc = function (key, opts = {}) {
  let out = this.t(key, opts)
  if (this.locale === 'fr')
    out += " "
  return  out + ":"
}

i18n.model_name = function (model, opts = {}) {
  const last_key = opts.plural ? 'other' : 'one'
  return this.t(`activerecord.models.${model}.${last_key}`)
}

i18n.attribute_name = function (model, attribute, opts = {}) {
  return this.t(`activerecord.attributes.${model}.${attribute}`)
}

i18n.enumerize = function (enumerize, key, opts = {}) {
  return this.t(`enumerize.${enumerize}.${key}`)
}

i18n.store(translations)
i18n.defaultLocale = "fr"
i18n.enableFallback = true
i18n.locale = userLocale
