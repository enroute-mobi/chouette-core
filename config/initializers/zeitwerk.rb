# frozen_string_literal: true

Rails.autoloaders.each do |loader|
  loader.inflector.inflect(
    {
      'sftp' => 'SFTP'
    }
  )
end

unless Rails.application.config.eager_load
  Rails.application.config.to_prepare do
    Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/jobs/cron'))

    Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/models/control'))
    Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/models/control/context'))
    Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/models/destination'))
    Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/models/export'))
    Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/models/import'))
    Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/models/macro'))
    Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/models/macro/context'))
    Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/models/point_of_interest'))
    Rails.autoloaders.main.eager_load_dir(Rails.root.join('app/models/processing_rule'))
  end
end
