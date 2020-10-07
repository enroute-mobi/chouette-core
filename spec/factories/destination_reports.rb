FactoryBot.define do
  factory :destination_report do
    association :destination
    association :publication
    status {nil}
    started_at {nil}
    ended_at {nil}

    before :create do | report |
      publication_setup = report.publication&.publication_setup
      publication_setup || report.destination&.publication_setup
      publication_setup || create(:publication_setup)

      report.publication ||= create(:publication, publication_setup: publication_setup)
      report.destination ||= create(:destination, publication_setup: publication_setup)

      report.publication.update publication_setup: publication_setup
      report.destination.update publication_setup: publication_setup
    end
  end
end
