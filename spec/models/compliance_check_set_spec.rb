
RSpec.describe ComplianceCheckSet, type: :model do
  it 'should have a valid factory' do
    expect(FactoryGirl.build(:compliance_check_set)).to be_valid
  end

  it { should belong_to :referential }
  it { should belong_to :workbench }
  it { should belong_to :compliance_control_set }
  it { should belong_to :parent }

  it { should have_many :compliance_checks }
  it { should have_many :compliance_check_blocks }


  describe '#perform' do
    let(:stub_validation_request) do
      stub_request(
        :get,
        "#{Rails.configuration.iev_url}/boiv_iev/referentials/validator/new?id=#{check_set.id }"
      )
    end
    let(:check_set){create :compliance_check_set, parent: create(:netex_import)}
    context "when the referential no longer exists" do
      let(:check_set){create :compliance_check_set, parent: create(:netex_import), referential: create(:referential)}
      before do
        check_set.referential.destroy
        check_set.reload
        check_set.perform
      end

      it "should abort" do
        expect(check_set.status).to eq "aborted"
      end
    end

    context "when JAVA is needed" do
      before do
        allow(check_set).to receive(:should_call_iev?).and_return(true)
        stub_validation_request
      end

      it "calls the Java API to launch validation" do
        check_set.perform
        expect(stub_validation_request).to have_been_requested
      end

      context "once java is done" do
        context "without internal checks" do
          it "should notify parent" do
            expect(check_set.parent).to receive(:child_change)
            check_set.notify_parent
          end
        end

        context "with internal checks" do
          before do
            check_set.compliance_checks.internals.create name: "foo", code: "foo", origin_code: "foo", compliance_control_name: "Dummy"
          end
          it "should perform internal checks and THEN notify parent" do
            expect(check_set.parent).to_not receive(:child_change)
            expect(check_set).to receive(:perform_async).with(true)
            check_set.notify_parent
          end
        end
      end
    end

    context "when JAVA is not needed" do
      before do
        stub_validation_request
        expect(check_set).to receive(:should_call_iev?).and_return(false)
      end

      it "should not call it" do
        expect(stub_validation_request).to_not have_been_requested
        expect(check_set.parent).to receive(:child_change)
        expect(check_set).to receive(:perform_internal_checks).and_call_original
        check_set.perform
      end

      context "when a check raises an error" do
        it "should update its status as failed" do
          check_set.compliance_checks.internals.create name: "foo", code: "foo", origin_code: "foo", compliance_control_name: "DummyControl::Dummy"
          allow(DummyControl::Dummy).to receive(:collection).and_return([create(:line)])
          allow(DummyControl::Dummy).to receive(:compliance_test).and_raise
          expect{check_set.perform}.to raise_error RuntimeError
          expect(check_set.status).to eq "failed"
        end
      end
    end
  end

  describe "#update_status" do
    it "updates :status to successful when all resources are OK" do
      check_set = create(:compliance_check_set)
      create_list(
        :compliance_check_resource,
        2,
        compliance_check_set: check_set,
        status: 'OK'
      )

      check_set.update_status

      expect(check_set.status).to eq('successful')
    end

    it "updates :status to failed when one resource is ERROR" do
      check_set = create(:compliance_check_set)
      create(
        :compliance_check_resource,
        compliance_check_set: check_set,
        status: 'ERROR'
      )
      create(
        :compliance_check_resource,
        compliance_check_set: check_set,
        status: 'OK'
      )

      check_set.update_status
      expect(check_set.reload.status).to eq('failed')
    end

    it "updates :status to warning when one resource is WARNING" do
      check_set = create(:compliance_check_set)
      create(
        :compliance_check_resource,
        compliance_check_set: check_set,
        status: 'WARNING'
      )
      create(
        :compliance_check_resource,
        compliance_check_set: check_set,
        status: 'OK'
      )

      check_set.update_status

      expect(check_set.reload.status).to eq('warning')
    end

    it "updates :status to successful when resources are IGNORED" do
      check_set = create(:compliance_check_set)
      create(
        :compliance_check_resource,
        compliance_check_set: check_set,
        status: 'IGNORED'
      )
      create(
        :compliance_check_resource,
        compliance_check_set: check_set,
        status: 'OK'
      )

      check_set.update_status

      expect(check_set.status).to eq('warning')
    end

  end

  describe 'possibility to delete the associated compliance_control_set' do
    let!(:compliance_check_set) { create :compliance_check_set }

    it do
      expect{ compliance_check_set.compliance_control_set.delete }
        .to change{ ComplianceControlSet.count }.by(-1)
    end
  end
end
