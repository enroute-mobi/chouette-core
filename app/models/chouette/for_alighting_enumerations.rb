module Chouette
  module ForAlightingEnumerations
    extend Enumerize
    extend ActiveModel::Naming

    enumerize :for_alighting, in: %w[normal forbidden], default: :normal
  end
end
