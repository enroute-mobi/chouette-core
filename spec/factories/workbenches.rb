FactoryBot.define do
  factory :workbench do
    name {"Gestion de l'offre"}
    objectid_format {'stif_netex'}
    prefix {'local'}
    restrictions {[]}

    association :organisation
    association :line_referential
    association :stop_area_referential
    association :output, factory: :referential_suite
    association :workgroup

    after(:create) do |workbench, evaluator|
      workbench.prefix ||= evaluator.organisation.code
    end
  end
end
