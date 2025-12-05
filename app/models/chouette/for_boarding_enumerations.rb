module Chouette
  module ForBoardingEnumerations
    extend Enumerize
    extend ActiveModel::Naming

    enumerize :for_boarding, in: %w[normal forbidden], default: :normal
  end
end
