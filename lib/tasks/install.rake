task :package do
  release_name = Time.now.strftime('%Y%m%d%H%M%S')

  rm_rf "tmp/package"
  mkdir_p "tmp/package"

  sh "git archive --format=tar --output=tmp/package/stif-boiv-release-#{release_name}.tar HEAD"

  sh "bundle package --all"
  sh "tar -rf tmp/package/stif-boiv-release-#{release_name}.tar vendor/cache"

  %w{deploy-helper.sh README sidekiq-stif-boiv.service stif-boiv.conf stif-boiv-setup.sh template-stif-boiv.sql}.each do |f|
    cp "install/#{f}", "tmp/package/#{f}"
  end

  sh "tar -czf stif-boiv-#{release_name}.tar.gz -C tmp/package ."
  sh "rm -rf tmp/package vendor/cache"
end
