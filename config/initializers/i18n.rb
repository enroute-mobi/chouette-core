module I18nTranslateWithFallback
  def translate key, options={}, original=nil
    options[:locale] ||= I18n.locale
    begin
      super(key, {raise: true}.update(options))
    rescue I18n::MissingTranslationData, I18n::InvalidPluralizationData
      # No capture
      split = key.to_s.split('.')
      if split.size <= 2
        super original || key, options
      else
        Rails.logger.warn do
          "DEPRECATION WARNING: missing i18n key \"#{key}\" falls back to original (I18nTranslateWithFallback)"
        end
        v = split.pop
        v2 = split.pop
        split.pop if v2 == "default"
        split << "default" << v
        new_key = split.join('.')
        translate new_key, options, original || key
      end
    end
  end


end

module I18n
  class << self
    alias_method :translate_without_fallback, :translate
    prepend I18nTranslateWithFallback

    alias_method :t, :translate
  end

  def self.tc(key, params={})
    self.t('label_with_colon', label: key.t(params)).html_safe
  end

  def self.tmf(key, params={})
    model, col = key.split "."
    begin
      self.t "activerecord.attributes.#{key}", {raise: true}.update(params)
    rescue
      begin
        self.t "activerecord.attributes.common.#{col}", {raise: true}.update(params)
      rescue
        begin
          self.t "simple_form.labels.#{key}", {raise: true}.update(params)
        rescue
          "activerecord.attributes.#{key}".t params
        end
      end
    end
  end

  def self.tmfc(key, params={})
    self.t('label_with_colon', label: self.tmf(key, params)).html_safe
  end

  def self.missing_keys_logger
    @@my_logger ||= Logger.new("#{Rails.root}/log/missing_keys.log")
  end

  def self.log_missing_key key, params={}
    missing_keys_logger.info "key: '#{key}', locale: '#{I18n.locale}', params: #{params}"
  end

  def self.t_with_default(key, params={})
    begin
      self.t(key, {raise: true}.update(params))
    rescue
      if Rails.env.development?
        log_missing_key key, params
        "<span class='label label-danger' title='#{self.t(key, params)}'>!</span>#{key.split('.').last}".html_safe
      else
        key.split('.').last
      end
    end
  end
end

module EnhancedI18n
  def t(params={})
    I18n.t_with_default(self, params)
  end

  def tc(params={})
    I18n.tc(self, params)
  end

  def tmf(params={})
    I18n.tmf(self, params)
  end

  def tmfc(params={})
    I18n.tmfc(self, params)
  end
end

module EnhancedTimeI18n
  def l(params={})
    I18n.l(self, params)
  end
end

class Symbol
  include EnhancedI18n
end

class String
  include EnhancedI18n
end

class Time
  include EnhancedTimeI18n
end

class DateTime
  include EnhancedTimeI18n
end

class Date
  include EnhancedTimeI18n
end

module EnhancedModelI18n
  # Human name of the class (plural)
  def t opts={}
    "activerecord.models.#{i18n_key}".t({count: 2}.update(opts))
  end

  # Human name of the class (singular)
  def ts opts={}
    self.t({count: 1}.update(opts))
  end

  # Human name of the class (with comma)
  def tc(params={})
    I18n.tc(i18n_key, params)
  end

  # Human name of the attribute
  def tmf(attribute, params={})
    I18n.tmf "#{i18n_key}.#{attribute}", params
  end

  def tmfc(attribute, params={})
    I18n.tmfc "#{i18n_key}.#{attribute}", params
  end

  # Translate the given action on the model, with default
  def t_action(action, params={})
    key = case action.to_sym
    when :create
      :new
    when :update
      :edit
    else
      action
    end

    begin
      I18n.translate_without_fallback "#{i18n_key.pluralize}.actions.#{key}", ({raise: true}.update(params))
    rescue
      if :index == action.to_sym
        begin
          I18n.translate_without_fallback "#{i18n_key.pluralize}.#{key}.title", ({raise: true}.update(params))
        rescue
          I18n.translate_without_fallback "#{key}.title", params
        end
      else
        I18n.translate_without_fallback "actions.#{key}", params
      end
    end
  end

  private
  def i18n_key
    # Use Rails model_name.i18n_key instead of our custom algorithm
    try(:custom_i18n_key) || model_name.i18n_key.to_s
  end
end

class ActiveRecord::Base
  extend EnhancedModelI18n
end

module ActiveModelNamingExtendedWithI18n
  def extended klass
    super klass
    klass.send :extend, EnhancedModelI18n
  end
end

module ActiveModel::Naming
  class << self
    prepend ActiveModelNamingExtendedWithI18n
  end
end

if Rails.env.development? && ENV['CHOUETTE_DEV_I18N_LISTEN'] == "true"
  Rails.application.config.after_initialize do
    require 'i18n-js/listen'
    puts "Start I18nJS.listenn"
    I18nJS.listen
  end
end
