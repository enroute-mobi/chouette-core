RSpec.describe ComplianceControlSetCopyWorker do
  let(:control_set_id) { 55 }
  let(:referential_id) { 99 }
  let(:check_set) { double(ComplianceCheckSet, id: 888) }
  let(:stub_validation_request) do
    stub_request(
      :get,
      "#{Rails.configuration.iev_url}/boiv_iev/referentials/validator/new?id=#{check_set.id}"
    )
  end

  before(:each) do
    allow_any_instance_of(
      ComplianceControlSetCopier
    ).to receive(:copy).and_return(check_set)
    allow(
      check_set
    ).to receive(:should_call_iev?).and_return(true)

    stub_validation_request
  end

  it "calls ComplianceControlSetCopier" do
    expect_any_instance_of(
      ComplianceControlSetCopier
    ).to receive(:copy)
      .with(control_set_id, referential_id)
      .and_return(check_set)

    ComplianceControlSetCopyWorker.new.perform(control_set_id, referential_id)
  end

  it "calls the Java API to launch validation" do
    ComplianceControlSetCopyWorker.new.perform(control_set_id, referential_id)

    expect(stub_validation_request).to have_been_requested
  end

  context "when JAVA is not needed" do
    before do
      expect(check_set).to receive(:should_call_iev?).and_return(false)
    end

    it "should not call it" do
      expect(stub_validation_request).to_not have_been_requested
      expect(check_set).to receive :perform_internal_checks
      ComplianceControlSetCopyWorker.new.perform(control_set_id, referential_id)
    end
  end
end
