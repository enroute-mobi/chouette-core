# frozen_string_literal: true

Rails.autoloaders.each do |loader|
  loader.inflector.inflect(
    {
      'sftp' => 'SFTP'
    }
  )
end
