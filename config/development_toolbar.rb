require Rails.root + 'app/models/permission.rb'
require Rails.root + 'app/models/feature.rb'

toolbar.available_features = ::Feature.all
permissions = Permission.full + Permission.workgroup_permissions; nil

permissions << "line_referentials.synchronize"; nil
permissions << "sidekiq.monitor"; nil
permissions << "merges.rollback"; nil

toolbar.available_permissions = permissions.uniq
toolbar.features_doc_url = "https://github.com/af83/chouette-core/wiki/Optional-Features"
