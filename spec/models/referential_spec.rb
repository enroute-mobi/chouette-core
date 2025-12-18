# frozen_string_literal: true

RSpec.describe Referential, type: :model do
  let(:context) do
    Chouette.create do
      referential
    end
  end
  let(:referential) { context.referential }

  it { should have_many(:metadatas) }
  it { is_expected.to belong_to(:workbench).optional }
  it { is_expected.to belong_to(:referential_suite).optional }

  context '#clean_scope' do
    let(:cooldown){ 30 }
    before(:each) do
       Referential.send :remove_const, 'TIME_BEFORE_CLEANING'
       Referential.const_set 'TIME_BEFORE_CLEANING', cooldown
     end

    it 'should be empty' do
      create(:referential, :bare)
      expect(Referential.clean_scope).to be_empty
    end

    context 'with an old Referential' do
      let(:old_referential) do
        old_referential = create(:workbench_referential, :bare)
        old_referential.active!
        old_referential
      end

      context 'archived' do
        before { old_referential.archived! }
        it 'should not contain it' do
          expect(Referential.clean_scope).to_not include old_referential
        end

        context "with #{Referential::KEPT_DURING_CLEANING} referentials after" do
          before do
            create_list(:referential, Referential::KEPT_DURING_CLEANING)
          end

          it 'should not contain it' do
            expect(Referential.clean_scope).to_not include old_referential
          end
        end

        context 'used in a merged offer' do
          before do
            other_referential = create(:referential, :bare)
            create(:referential_metadata, referential: other_referential, referential_source: old_referential)
          end
          it 'should not contain it' do
            expect(Referential.clean_scope).to_not include old_referential
          end
        end

      end

      context 'archived more than a month ago' do
        before(:each) do
           old_referential.archived!
           old_referential.update archived_at: Referential::TIME_BEFORE_CLEANING.days.ago.prev_day
         end

        it 'should not contain it' do
          expect(Referential.clean_scope).to_not include old_referential
        end

        context "with #{Referential::KEPT_DURING_CLEANING} referentials after" do
          before do
            old_referential
            create_list(:referential, Referential::KEPT_DURING_CLEANING, :bare)
          end

          it 'should contain it' do
            expect(Referential.clean_scope).to include old_referential
          end

          context 'which is a merged offer' do
            before do
              create(:referential_suite, referentials: [old_referential])
            end
            it 'should not contain it' do
              expect(Referential.clean_scope).to_not include old_referential
            end
          end

          context 'scoped in a workbench' do
            it 'should only account for referentials in the workbench' do
              expect(old_referential.workbench.referentials.clean_scope).to_not include old_referential
              create_list(:workbench_referential, Referential::KEPT_DURING_CLEANING, :bare, workbench: old_referential.workbench)
              expect(old_referential.workbench.referentials.clean_scope).to include old_referential
            end
          end

          context 'with Referential::KEPT_DURING_CLEANING zeroed' do
            let(:cooldown){ 0 }

            it 'should be empty' do
              expect(Referential.clean_scope).to be_empty
            end
          end

          context 'used in a merged offer' do
            before do
              other_referential = create(:referential, :bare)
              create(:referential_metadata, referential: other_referential, referential_source: old_referential)
            end
            it 'should not contain it' do
              expect(Referential.clean_scope).to_not include old_referential
            end
          end
        end
      end

      context 'active' do
        before { old_referential.active! }

        it 'should not contain it' do
          expect(Referential.clean_scope).to_not include old_referential
        end

        context "with #{Referential::KEPT_DURING_CLEANING} referentials after" do
          before do
            old_referential
            create_list(:referential, Referential::KEPT_DURING_CLEANING, :bare)
          end

          it 'should not contain it' do
            expect(Referential.clean_scope).to_not include old_referential
          end
        end
      end
    end
  end

  context "validation" do
    subject { build(:referential) }

    it { should validate_presence_of(:objectid_format) }

    context "without concurent referential on same lines and dates" do
      it { should be_valid }
    end

    context "with concurent referential on same lines and dates" do
      let(:other){
        metadatas = create :referential_metadata
        metadatas.line_ids = referential.metadatas.first.line_ids
        metadatas.periodes = referential.metadatas.first.periodes
        build(
          :workbench_referential,
          metadatas: [metadatas],
          workbench: referential.workbench,
          organisation: referential.organisation
        )
      }

      it "should not be_valid" do
        expect(other).to_not be_valid
      end

      context "when the other is not active" do
        before { referential.failed! }

        it "should be_valid" do
          expect(other).to be_valid
        end
      end

      context "with metadatas on a single day" do
        before { referential.metadatas.first.update periodes: [(Time.now.to_date..Time.now.to_date)] }

        it "should not be_valid" do
          expect(other).to_not be_valid
        end
      end
    end
  end

  context "creation" do
    subject(:referential) { Referential.create name: "test", objectid_format: :netex, organisation: create(:organisation), line_referential: create(:line_referential), stop_area_referential: create(:stop_area_referential), prefix: "foo" }

    it "should not clone the current offer" do
      @create_from_current_offer = false
      allow_any_instance_of(Referential).to receive(:create_from_current_offer){ @create_from_current_offer = true }
      referential
      expect(@create_from_current_offer).to be_falsy
    end

    context 'with create_from_current_offer' do
      subject(:referential) { Referential.create name: "test", objectid_format: :netex, organisation: create(:organisation), line_referential: create(:line_referential), stop_area_referential: create(:stop_area_referential), prefix: "foo", from_current_offer: true }

      it 'should call the dedicated method' do
        called = false
        allow_any_instance_of(Referential).to receive(:create_from_current_offer) { called = true }

        referential

        expect(called).to be_truthy
      end
    end
  end

  context ".last_operation" do
    subject(:operation) { referential.last_operation }

    it "should return nothing" do
      expect(operation).to be_nil
    end

    context "with a netex import" do
      let!(:import) do
        import = create :netex_import
        import.referential = referential
        import.save
        import
      end

      it "should return the import" do
        expect(operation).to eq import
      end
    end

    context "with 2 netex imports" do
      let!(:other_import) do
        import = create :netex_import
        import.referential = referential
        import.save
        import
      end
      let!(:import) do
        import = create :netex_import
        import.referential = referential
        import.save
        import
      end

      it "should return the last import" do
        expect(operation).to eq import
      end
    end

    context "with a gtfs import" do
      let!(:import) do
        import = create :gtfs_import
        import.referential = referential
        import.save
        import
      end

      it "should return the import" do
        expect(operation).to eq import
      end
    end

    context "with a cleanup" do
      let!(:cleanup) do
        cleanup = create :clean_up
        cleanup.referential = referential
        cleanup.save
        cleanup
      end

      it "should return the cleanup" do
        expect(operation).to eq cleanup
      end
    end
  end

  context "clean_routes_if_needed" do
    before(:each) do
      3.times do create(:line, line_referential: referential.line_referential) end
      m = referential.metadatas.last
      m.update_column :line_ids, referential.associated_lines.map(&:id)
      referential.switch do
        create(:route, line: referential.lines.order(:id).last)
      end
    end
    context "when the lines did not change" do
      it "should do nothing" do
        expect(CleanUp).to_not receive(:create)
        referential.clean_routes_if_needed
      end
    end

    context "when the lines changed" do
      before do
        m = referential.metadatas.last
        m.update_column :line_ids, m.line_ids.sort[0...-1]
        referential.reload
      end
      it "should perform cleanup" do
        expect(CleanUp).to receive(:create!).with({ referential: referential, original_state: referential.state })
        referential.clean_routes_if_needed
        expect(referential.reload.state).to eq :pending
      end
    end
  end

  describe 'state' do
    let(:pending_referential) { Chouette.create { referential }.referential.tap(&:pending!) }
    let(:active_referential) { Chouette.create { referential }.referential.tap(&:active!) }
    let(:failed_referential) { Chouette.create { referential }.referential.tap(&:failed!) }
    let(:archived_referential) { Chouette.create { referential }.referential.tap(&:archived!) }

    describe '#state' do
      subject { referential.state }

      context 'with pending referential' do
        let(:referential) { pending_referential }
        it { is_expected.to eq(:pending) }
      end

      context 'with active referential' do
        let(:referential) { active_referential }
        it { is_expected.to eq(:active) }
      end

      context 'with failed referential' do
        let(:referential) { failed_referential }
        it { is_expected.to eq(:failed) }
      end

      context 'with archived referential' do
        let(:referential) { archived_referential }
        it { is_expected.to eq(:archived) }
      end

      context 'with #data_freeze_status' do
        let(:referential) { archived_referential }

        context 'with freezing referential' do
          before { referential.data_freeze_status = 'freezing' }
          it { is_expected.to eq(:frozen) }
        end

        context 'with frozen referential' do
          before { referential.data_freeze_status = 'frozen' }
          it { is_expected.to eq(:frozen) }
        end

        context 'with unfreeze_enqueued referential' do
          before { referential.data_freeze_status = 'unfreeze_enqueued' }
          it { is_expected.to eq(:unfreezing) }
        end

        context 'with unfreezing referential' do
          before { referential.data_freeze_status = 'unfreezing' }
          it { is_expected.to eq(:unfreezing) }
        end
      end
    end

    describe 'scopes' do
      before do
        pending_referential
        active_referential
        failed_referential
        archived_referential
      end

      it '.pending' do
        expect(described_class.pending).to include(pending_referential)
      end

      it '.active' do
        expect(described_class.active).to include(active_referential)
      end

      it '.failed' do
        expect(described_class.failed).to include(failed_referential)
      end

      it '.archived' do
        expect(described_class.archived).to include(archived_referential)
      end
    end

    context 'pending_while' do
      it "should preserve the state" do
        referential = archived_referential
        referential.pending_while do
          expect(referential.state).to eq :pending
        end
        expect(referential.state).to eq :archived
        begin
          referential.pending_while do
            expect(referential.state).to eq :pending
            raise
          end
        rescue
        end
        expect(referential.state).to eq :archived
      end
    end
  end

  describe "#workgroup" do

    context "when is referential" do
      let(:ref1) {  create(:referential) }
      let(:ref2) {  create(:workbench_referential) }

      it "should return workbench's workgroup" do
        expect(ref1.workgroup).to be_nil
        expect(ref2.workgroup).to eq(ref2.workbench.workgroup)
      end
    end

    context "when is merged offer" do
      let!(:ref_suite) {  ReferentialSuite.create }
      let!(:workgroup) { create(:workgroup, output: ref_suite) }
      let(:ref1) {  create(:referential,  referential_suite: ref_suite) }
      let(:ref2) {  create(:referential) }

      it "should returns workgroup that output is the same as referential suite" do
        expect(ref1.workgroup).to eq(workgroup)
        expect(ref2.workgroup).to be_nil
      end
    end
  end

  context ".referential_ids_in_periode" do
    it 'should retrieve referential id in periode range' do
      range = referential.metadatas.first.periodes.sample
      refs  = Referential.referential_ids_in_periode(range)
      expect(refs).to include(referential.id)
    end

    it 'should not retrieve referential id not in periode range' do
      range = Date.today - 2.year..Date.today - 1.year
      refs  = Referential.referential_ids_in_periode(range)
      expect(refs).to_not include(referential.id)
    end
  end

  context "schema creation" do

    it "should create a schema named as the slug" do
      referential = FactoryBot.create :referential
      expect(referential.migration_count).to be >= 1
    end

  end

  context "Cloning referential" do
    let(:clone) do
      Referential.new_from(referential, referential.workbench)
    end

    let!(:workbench){ create :workbench }

    let(:saved_clone) do
      clone.tap do |clone|
        clone.organisation = workbench.organisation
        clone.workbench = workbench
        clone.metadatas = [create(:referential_metadata, referential: clone)]
        clone.save!
      end
    end

    it 'should create a Referential' do
      referential
      expect { saved_clone }.to change{Referential.count}.by(1)
      expect(saved_clone.state).to eq :pending
    end

    xit 'should create a ReferentialCloning' do
      expect { saved_clone }.to change{ReferentialCloning.count}.by(1)
    end

    def metadatas_attributes(referential)
      referential.metadatas.map { |m| [ m.periodes, m.line_ids ] }
    end

    xit 'should clone referential_metadatas' do
      expect(metadatas_attributes(clone)).to eq(metadatas_attributes(referential))
    end
  end

  describe "metadatas" do
    context "nested attributes support" do
      let(:context) do
        Chouette.create do
          organisation :organisation
          workgroup owner: :organisation do
            workbench organisation: :organisation do
              line :line1
              line :line2
              line :line3
            end
          end
        end
      end
      let(:organisation) { context.organisation(:organisation) }
      let(:workbench) { context.workbench }
      let(:lines) { %i[line1 line2 line3].map { |l| context.line(l) } }

      let(:attributes) do
        {
          "organisation_id" => organisation.id,
          "name"=>"Test",
          "slug"=>"test",
          "prefix"=>"test",
          "time_zone"=>"American Samoa",
          "upper_corner"=>"51.1,8.23",
          "lower_corner"=>"42.25,-5.2",
          "data_format"=>"neptune",
          "metadatas_attributes"=> {
            "0"=> {
              "periods_attributes" => {
                "0" => {
                  "begin"=>"2016-09-19",
                  "end" => "2016-10-19",
                },
                "15918593" => {
                  "begin"=>"2016-11-19",
                  "end" => "2016-12-19",
                },
              },
              "lines"=> [""] + lines.map { |l| l.id.to_s }
            }
          },
          "workbench_id" => workbench.id,
        }
      end

      let(:new_referential) { Referential.new(attributes) }
      let(:first_metadata) { new_referential.metadatas.first }

      let(:expected_ranges) do
        [
          Range.new(Date.new(2016,9,19), Date.new(2016,10,19)),
          Range.new(Date.new(2016,11,19), Date.new(2016,12,19)),
        ]
      end

      it "should create a metadata" do
        expect(new_referential.metadatas.size).to eq(1)
      end

      it "should define metadata periods" do
        expect(first_metadata.periods.map(&:range)).to eq(expected_ranges)
      end

      it "should define periodes" do
        new_referential.save!
        expect(first_metadata.periodes).to eq(expected_ranges)
      end

      it "should define period" do
        new_referential.save!
        expect(first_metadata.lines).to eq(lines)
      end
    end
  end

  context "to be referential_read_only or not to be referential_read_only" do
    let( :referential ){ build( :referential ) }

    context "in the beginning" do
      it{ expect( referential ).not_to be_referential_read_only }
    end

    context "after archivation" do
      before{ referential.archived_at = 1.day.ago }
      it{ expect( referential ).to be_referential_read_only }
    end

    context "used in a ReferentialSuite" do
      before { referential.referential_suite_id = 42 }

      it{ expect( referential ).to be_referential_read_only }

      it "return true to in_referential_suite?" do
        expect(referential).to be_in_referential_suite
      end

      it "don't use detect_overlapped_referentials in validation" do
        expect(referential).to_not receive(:detect_overlapped_referentials)
        expect(referential).to be_valid
      end
    end

    context "archived and finalised" do
      before do
        referential.archived_at = 1.month.ago
        referential.referential_suite_id = 53
      end
      it{ expect( referential ).to be_referential_read_only }
    end
  end

  context "urgent" do

    # Time.now.round simplifies Time comparaison in specs
    around { |example| Timecop.freeze(Time.now.round) { example.run } }

    context "with a persisted Referential" do
      before { referential.reload }

      def metadatas_flagged_urgent_at
        referential.metadatas.map(&:flagged_urgent_at)
      end

      describe "#flag_metadatas_as_urgent!" do
        it "defines flagged_urgent_at in all metadatas" do
          expect do
            referential.flag_metadatas_as_urgent!
          end.to change { metadatas_flagged_urgent_at.uniq }.from([nil]).to([Time.now])
        end
      end

      describe "#flag_not_urgent!" do
        before { referential.flag_metadatas_as_urgent! }
        it "reset flagged_urgent_at in all metadatas" do
          expect do
            referential.flag_not_urgent!
          end.to change { metadatas_flagged_urgent_at.uniq }.to([nil])
        end
      end

    end

    context "with a new Referential" do

      let(:referential) do
        Referential.new.tap do |referential|
          2.times { referential.metadatas.build }
          referential.metadatas.load
        end
      end

      def metadatas_flagged_urgent_at
        referential.metadatas.map(&:flagged_urgent_at)
      end

       describe "#flag_metadatas_as_urgent!" do
        it "defines flagged_urgent_at in all metadatas" do
          expect do
            referential.flag_metadatas_as_urgent!
          end.to change { metadatas_flagged_urgent_at.uniq }.from([nil]).to([Time.now])
        end
      end

      describe "#flag_not_urgent!" do
        before { referential.flag_metadatas_as_urgent! }
        it "reset flagged_urgent_at in all metadatas" do
          expect do
            referential.flag_not_urgent!
          end.to change { metadatas_flagged_urgent_at.uniq }.to([nil])
        end
      end


    end

  end

  it { is_expected.to enumerize(:data_freeze_status).in(%w[unfrozen freezing frozen unfreeze_enqueued unfreezing]) }

  describe '.data_unfrozen' do
    subject { described_class.data_unfrozen }

    context 'when #data_freeze_status is "unfrozen"' do
      before { referential }
        it { is_expected.to include(referential) }
    end

    %w[freezing frozen unfreeze_enqueued unfreezing].each do |data_freeze_status|
      context "when #data_freeze_status is \"#{data_freeze_status}\"" do
        before { referential.update!(data_freeze_status: data_freeze_status) }
        it { is_expected.to be_empty }
      end
    end
  end

  describe '#data_frozen?' do
    subject { referential.data_frozen? }

    context 'when #data_freeze_status is "unfrozen"' do
      it { is_expected.to eq(false) }
    end

    %w[freezing frozen unfreeze_enqueued unfreezing].each do |data_freeze_status|
      context "when #data_freeze_status is \"#{data_freeze_status}\"" do
        before { referential.data_freeze_status = data_freeze_status }
        it { is_expected.to eq(true) }
      end
    end
  end

  describe '#data_freeze', truncation: true do
    subject { referential.data_freeze }

    it 'attaches dump file' do
      subject
      expect(referential.frozen_dump).to be_attached
    end

    it 'destroys schema' do
      subject
      expect { referential.switch }.to raise_error(Apartment::TenantNotFound)
    end

    it { expect { subject }.to change { referential.reload.data_freeze_status }.from('unfrozen').to('frozen') }

    it { expect { subject }.to change { referential.reload.ready? }.from(true).to(false) }

    it 'removes schema from apartment tenants' do
      expect { subject }.to change { Apartment.tenant_names }.from(include(referential.slug))
                                                             .to(not_include(referential.slug))
    end

    context 'with CrossReferentialIndexEntry' do
      let(:context) do
        Chouette.create do
          line_notice :line_notice
          referential do
            vehicle_journey line_notices: %i[line_notice]
          end
        end
      end
      let(:line_notice) { context.line_notice(:line_notice) }

      it 'does not crash when rebuilding all CrossReferentialIndexEntry' do
        subject
        expect(Chouette::Safe).not_to receive(:capture)
        CrossReferentialIndexEntry.rebuild_index!
      end

      it 'does not crash when line_notice retrieves its vehicle journeys' do
        expect(line_notice.reload.vehicle_journeys.count).to eq(1)
        subject
        expect(line_notice.reload.vehicle_journeys.count).to eq(0)
      end
    end

    context 'with errors' do
      context 'when dump file is empty' do
        before { allow(referential.schema).to receive(:dump) }

        it 'does not attach dump file' do
          subject
          expect(referential.frozen_dump).not_to be_attached
        end

        it 'does not destroy schema' do
          expect { referential.switch }.not_to raise_error
        end

        it { expect { subject }.not_to change { referential.reload.data_freeze_status }.from('unfrozen') }

        it { expect { subject }.not_to change { referential.reload.ready? }.from(true) }

        it 'does not remove schema from apartment tenants' do
          expect { subject }.not_to change { Apartment.tenant_names }.from(include(referential.slug))
        end
      end

      context 'when schema could not be destroyed' do
        subject { super() rescue nil } # rubocop:disable Style/RescueModifier

        before do
          allow(referential.schema).to receive(:destroy!).and_wrap_original do |m, *args|
            m.call(*args)
            raise StandardError, 'Oops'
          end
        end

        it 'attaches dump file' do
          subject
          expect(referential.frozen_dump).to be_attached
        end

        it 'does not destroy schema' do
          expect { referential.switch }.not_to raise_error
        end

        it { expect { subject }.not_to change { referential.reload.data_freeze_status }.from('unfrozen') }

        it { expect { subject }.not_to change { referential.reload.ready? }.from(true) }

        it 'does not remove schema from apartment tenants' do
          expect { subject }.not_to change { Apartment.tenant_names }.from(include(referential.slug))
        end
      end
    end
  end

  describe '#enqueue_data_unfreeze' do
    subject { referential.enqueue_data_unfreeze }

    before { referential.update(data_freeze_status: 'frozen', ready: false) }

    it { expect { subject }.to change { referential.reload.data_freeze_status }.from('frozen').to('unfreeze_enqueued') }

    it { expect { subject }.not_to change { referential.reload.ready? }.from(false) }

    it { expect { subject }.to change { Delayed::Job.count }.by(1) }

    it do
      subject
      expect(Delayed::Job.last.handler).to match(/Referential::DataUnfreezeJob/)
    end

    context 'when update fails' do
      before { allow(referential).to receive(:update).and_return(false) }
      it { expect { subject }.not_to change { Delayed::Job.count } }
    end
  end

  describe '#data_unfreeze', truncation: true do
    subject { referential.data_unfreeze }

    let!(:public_current_version) { ActiveRecord::Migrator.current_version }

    let(:context) do
      frozen_dump = file_fixture('referential_dump.sql.gz').open
      Chouette.create do
        referential(slug: '5c630290-96ff-4186-afb5-8bc5be256e3a', frozen_dump: frozen_dump)
      end
    end

    before do
      referential.schema.destroy!
      referential.update(data_freeze_status: 'unfreeze_enqueued', ready: false)
    end

    after { Apartment::Tenant.drop('5c630290-96ff-4186-afb5-8bc5be256e3a') rescue nil } # rubocop:disable Style/RescueModifier

    it 'restores data' do
      subject
      expect { referential.switch }.not_to raise_error
      expect(Chouette::Route).to be_exists
    end

    it 'applies migrations' do
      subject
      referential.switch
      expect(ActiveRecord::Migrator.current_version).to eq(public_current_version)
    end

    it 'removes dump file' do
      subject
      expect(referential.frozen_dump).not_to be_attached
    end

    it do
      expect { subject }.to change { referential.reload.data_freeze_status }.from('unfreeze_enqueued').to('unfrozen')
    end

    it { expect { subject }.to change { referential.reload.ready? }.from(false).to(true) }

    it 'restores schema in apartment tenants' do
      expect { subject }.to change { Apartment.tenant_names }.from(not_include(referential.slug))
                                                             .to(include(referential.slug))
    end

    context 'with errors' do
      context 'when data could not be restored' do
        subject { super() rescue nil } # rubocop:disable Style/RescueModifier

        before do
          allow(referential.schema).to(
            receive(:restore).and_raise(Referential::Schema::DumpRestore::Error.new(%w[:], [42], 'error'))
          )
        end

        it 'does not remove dump file' do
          subject
          expect(referential.frozen_dump).to be_attached
        end

        it do
          expect { subject }.to(
            change { referential.reload.data_freeze_status }.from('unfreeze_enqueued').to('unfreezing')
          )
        end

        it { expect { subject }.not_to change { referential.reload.ready? }.from(false) }

        it 'does not restore schema in apartment tenants' do
          expect { subject }.not_to change { Apartment.tenant_names }.from(not_include(referential.slug))
        end
      end

      context 'when migration fails' do
        subject { super() rescue nil } # rubocop:disable Style/RescueModifier

        before { allow(referential.schema).to receive(:migrate).and_raise(StandardError.new('Oops')) }

        it 'restores data' do
          subject
          expect { referential.switch }.not_to raise_error
        end

        it 'does not remove dump file' do
          subject
          expect(referential.frozen_dump).to be_attached
        end

        it do
          expect { subject }.to(
            change { referential.reload.data_freeze_status }.from('unfreeze_enqueued').to('unfreezing')
          )
        end

        it { expect { subject }.not_to change { referential.reload.ready? }.from(false) }

        it 'does not restore schema in apartment tenants' do
          expect { subject }.not_to change { Apartment.tenant_names }.from(not_include(referential.slug))
        end
      end

      context 'when dump file could not be purged' do
        subject { super() rescue nil } # rubocop:disable Style/RescueModifier

        before { allow(referential.frozen_dump).to receive(:purge).and_raise(StandardError.new('Oops')) }

        it 'restores data and applies migrations' do
          subject
          expect { referential.switch }.not_to raise_error
          expect(ActiveRecord::Migrator.current_version).to eq(public_current_version)
        end

        it do
          expect { subject }.to(
            change { referential.reload.data_freeze_status }.from('unfreeze_enqueued').to('unfreezing')
          )
        end

        it { expect { subject }.not_to change { referential.reload.ready? }.from(false) }

        it 'does not restore schema in apartment tenants' do
          expect { subject }.not_to change { Apartment.tenant_names }.from(not_include(referential.slug))
        end
      end
    end
  end

  describe '#data_freeze + #data_unfreeze', truncation: true do
    subject do
      referential.data_freeze
      referential.data_unfreeze
    end

    let(:context) do
      Chouette.create do
        line :line
        line_notice :line_notice

        referential lines: %i[line] do
          footnote :footnote

          time_table :time_table

          route :route, line: :line, with_stops: false do
            stop_point :stop_point
            stop_point
            stop_point

            journey_pattern :journey_pattern do
              vehicle_journey :vehicle_journey,
                              footnotes: %i[footnote],
                              time_tables: %i[time_table],
                              line_notices: %i[line_notice]
            end

            routing_constraint_zone :routing_constraint_zone
          end
        end
      end.tap do |context|
        context.referential.switch do
          ServiceCount.create!(
            line_id: context.line(:line).id,
            route_id: context.route(:route).id,
            journey_pattern_id: context.journey_pattern(:journey_pattern).id,
            date: '2025-02-04'
          )
        end
      end
    end
    let(:models) do
      %i[
        footnote
        time_table
        route
        stop_point
        journey_pattern
        vehicle_journey
        routing_constraint_zone
      ].map { |i| context.send(i, i) } + [ServiceCount.first]
    end
    let(:line_notice) { context.line_notice(:line_notice) }

    it 'restores all models as if nothing happened' do
      referential.switch { models }
      subject
      referential.switch
      models.each do |model|
        expect { model.reload }.not_to raise_error
      end
    end

    context 'with CrossReferentialIndexEntry' do
      it 'does not crash when rebuilding all CrossReferentialIndexEntry' do
        subject
        expect(Chouette::Safe).not_to receive(:capture)
        CrossReferentialIndexEntry.rebuild_index!
      end

      it 'line_notice finds back its vehicle journeys' do
        expect(line_notice.reload.vehicle_journeys.count).to eq(1)
        subject
        expect(line_notice.reload.vehicle_journeys.count).to eq(1)
      end
    end
  end

  describe '.data_freeze_candidates' do
    subject { context.workbench.referentials.data_freeze_candidates }

    let(:referentials_frozen_after) { 14 }
    let!(:context) do
      Chouette.create do
        frozen_after = 14
        workbench do
          referential :never_visited, archived_at: Time.zone.now, name: 'never visited'
          referential :visited_recently, archived_at: Time.zone.now, visited_at: (frozen_after / 2).days.ago
          referential :visited_formerly, archived_at: Time.zone.now, visited_at: (frozen_after * 2).days.ago
          referential :in_a_referential_suite, archived_at: Time.zone.now
          referential :not_archived
        end
      end.tap do |context|
        context.referential(:in_a_referential_suite).update!(referential_suite: context.workbench.output)
      end
    end

    before { allow(Chouette::Config).to receive(:referentials_frozen_after).and_return(referentials_frozen_after) }

    context 'when Chouette::Config.referentials_frozen_after is set' do
      it 'returns only freezable candidates' do
        is_expected.to match_array(%i[never_visited visited_formerly].map { |r| context.referential(r) })
      end
    end

    context 'when Chouette::Config.referentials_frozen_after is nil' do
      let(:referentials_frozen_after) { nil }
      it { is_expected.to be_empty }
    end
  end
end

RSpec.describe Referential::DataUnfreezeJob do
  subject(:job) { described_class.new(referential) }

  let(:referential) do
    Chouette.create do
      referential data_freeze_status: 'unfreeze_enqueued', ready: false
    end.referential
  end

  describe '#perform' do
    subject { job.perform }

    it 'calls Referential#data_unfreeze' do
      expect(referential).to receive(:data_unfreeze)
      subject
    end

    %w[unfrozen freezing frozen unfreezing].each do |data_freeze_status|
      context "when #data_freeze_status is \"#{data_freeze_status}\"" do
        before { referential.update(data_freeze_status: data_freeze_status) }

        it 'does not call Referential#data_unfreeze' do
          expect(referential).not_to receive(:data_unfreeze)
          subject
        end
      end
    end
  end
end
