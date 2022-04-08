module Query
  class Company < Base
    def without_country
      scope.where(country_code: nil)
    end
  end
end