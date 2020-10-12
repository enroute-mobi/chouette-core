FactoryBot.define do
  factory :kml_export do
    referential { Referential.find_by_slug("first") }
  end
end
