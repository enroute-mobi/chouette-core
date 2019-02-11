RSpec.shared_context 'with an exportable referential' do
  let(:stop_area_referential){ create :stop_area_referential }
  let(:line_referential){ create :line_referential }
  let(:company){ create :company, line_referential: line_referential }
  let(:workbench){ create :workbench, line_referential: line_referential, stop_area_referential: stop_area_referential }
  let(:referential_metadata){ create(:referential_metadata, lines: line_referential.lines.limit(3)) }
  let(:referential){
    create :referential,
    workbench: workbench,
    organisation: workbench.organisation,
    metadatas: [referential_metadata]
  }

  before(:each) do
    2.times { create :line, line_referential: line_referential, company: company, network: nil }
    8.times { create :stop_area, stop_area_referential: stop_area_referential }
    2.times { create :stop_area,
      stop_area_referential: stop_area_referential,
      kind: "non_commercial",
      area_type: Chouette::AreaType.non_commercial.sample
    }
  end
end

RSpec.configure do |conf|
  conf.include_context 'with an exportable referential', type: :with_exportable_referential
end
