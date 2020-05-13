Rails.application.config.iev_url = SmartEnv['IEV_URL']
Rails.application.config.rails_host = SmartEnv['RAILS_HOST']
Rails.application.config.link_to_support_enabled = SmartEnv.boolean('ENABLE_LINK_TO_SUPPORT')
Rails.application.config.support_link = SmartEnv['SUPPORT_LINK']
