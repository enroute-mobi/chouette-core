FactoryBot.define do
  factory :workbench do
    name {"Gestion de l'offre"}
    objectid_format {'netex'}
    prefix {'local'}
    restrictions {[]}

    invitation_code { nil }

    association :organisation
    association :line_referential
    association :stop_area_referential
    association :output, factory: :referential_suite
    association :workgroup

    after(:create) do |workbench, evaluator|
      # create_list(:stop_area_provider, 1, workbench: workbench, stop_area_referential: workbench.stop_area_referential)
      workbench.prefix ||= evaluator.organisation.code
    end
  end
end
