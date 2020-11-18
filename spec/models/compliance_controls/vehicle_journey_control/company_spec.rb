RSpec.describe VehicleJourneyControl::Company, type: :model do
  let(:workgroup) { referential.workgroup }
  let(:line) {
    create :line, line_referential: workgroup.line_referential,
                  company: company,
                  secondary_company_ids: [secondary_company.id]
  }
  let(:route) { create :route, line: line }
  let(:journey_pattern) { create :journey_pattern, route: route }

  let(:company) { create :company, line_referential: workgroup.line_referential }
  let(:secondary_company) { create :company }

  let(:journey) { create :vehicle_journey_empty, journey_pattern: journey_pattern,
                                                 route: route,
                                                 company: company,
                                                 published_journey_name: '4' }

  let(:criticity) { 'warning' }

  let(:compliance_check_set) { create :compliance_check_set, referential: referential }
  let(:compliance_check) {
    create :compliance_check_with_compliance_check_block,
      iev_enabled_check: false,
      compliance_control_name: 'VehicleJourneyControl::Company',
      compliance_check_set: compliance_check_set,
      criticity: criticity
  }

  before do
    create(:referential_metadata, lines: [line], referential: referential)
    referential.reload
    referential.switch do
      journey
    end
  end

  it 'should pass if the company is the right one' do
    expect { compliance_check.process }.to change { ComplianceCheckResource.count }.by 1

    expect(ComplianceCheckResource.last.status).to eq 'OK'
  end

  it 'should pass if the line has no company' do
    referential.switch do
      line.company = nil
      line.save
    end

    expect { compliance_check.process }.to change { ComplianceCheckResource.count }.by 1

    expect(ComplianceCheckResource.last.status).to eq 'OK'
  end

  it 'should pass if no company is defined' do
    referential.switch do
      journey.company = nil
      journey.save
    end

    expect { compliance_check.process }.to change { ComplianceCheckResource.count }.by 1

    expect(ComplianceCheckResource.last.status).to eq 'OK'
  end

  it 'should pass if the company is a secondary company' do
    referential.switch do
      journey.company = secondary_company
      journey.save
    end

    expect { compliance_check.process }.to change { ComplianceCheckResource.count }.by 1

    expect(ComplianceCheckResource.last.status).to eq 'OK'
  end

  context 'with a wrong company' do
    before do
      referential.switch do
        journey.company = create :company
        journey.save
      end
    end

     context 'when the criticity is warning' do
      it 'should set the status according to its params' do
        expect { compliance_check.process }.to change { ComplianceCheckResource.count }.by 1

        expect(ComplianceCheckResource.last.status).to eq 'WARNING'
      end

      it 'should create a message' do
        expect { compliance_check.process }.to change { ComplianceCheckMessage.count }.by 1

        message = ComplianceCheckMessage.last
        expect(message.status).to eq 'WARNING'
        expect(message.compliance_check_set).to eq compliance_check_set
        expect(message.compliance_check).to eq compliance_check
        expect(message.compliance_check_resource).to eq ComplianceCheckResource.last
      end
    end

    context 'when the criticity is error' do
      let(:criticity) { 'error' }

      it 'should set the status according to its params' do
        expect { compliance_check.process }.to change { ComplianceCheckResource.count }.by 1

        expect(ComplianceCheckResource.last.status).to eq 'ERROR'
      end

      it 'should create a message' do
        expect { compliance_check.process }.to change{ ComplianceCheckMessage.count }.by 1

        message = ComplianceCheckMessage.last
        expect(message.status).to eq 'ERROR'
        expect(message.compliance_check_set).to eq compliance_check_set
        expect(message.compliance_check).to eq compliance_check
        expect(message.compliance_check_resource).to eq ComplianceCheckResource.last
      end
    end
  end
end
