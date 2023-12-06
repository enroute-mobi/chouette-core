describe Referential, :type => :model do
  let(:ref) { create :workbench_referential, metadatas: [create(:referential_metadata)] }

  it { should have_many(:metadatas) }
  it { is_expected.to belong_to(:workbench).required(false) }
  it { is_expected.to belong_to(:referential_suite).required(false) }

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
        metadatas.line_ids = ref.metadatas.first.line_ids
        metadatas.periodes = ref.metadatas.first.periodes
        build :workbench_referential, metadatas: [metadatas], workbench: ref.workbench, organisation: ref.organisation
      }

      it "should not be_valid" do
        expect(other).to_not be_valid
      end

      context "when the other is not active" do
        before{
          ref.failed!
        }

        it "should be_valid" do
          expect(other).to be_valid
        end
      end

      context "with metadatas on a single day" do
        before{
          ref.metadatas.first.update periodes: [(Time.now.to_date..Time.now.to_date)]
        }

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
    subject(:operation){ referential.last_operation }
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
    before(:each){
      3.times do create(:line, line_referential: ref.line_referential) end
      m = ref.metadatas.last
      m.update_column :line_ids, ref.associated_lines.map(&:id)
      ref.switch do
        create(:route, line: ref.lines.order(:id).last)
      end
    }
    context "when the lines did not change" do
      it "should do nothing" do
        expect(CleanUp).to_not receive(:create)
        ref.clean_routes_if_needed
      end
    end

    context "when the lines changed" do
      before do
        m = ref.metadatas.last
        m.update_column :line_ids, m.line_ids.sort[0...-1]
        ref.reload
      end
      it "should perform cleanup" do
        expect(CleanUp).to receive(:create!).with({referential: ref, original_state: ref.state})
        ref.clean_routes_if_needed
        expect(ref.reload.state).to eq :pending
      end
    end
  end

  context ".state" do
    it "should return the expected values" do
      referential = build :referential
      referential.ready = false
      expect(referential.state).to eq :pending
      referential.failed_at = Time.now
      expect(referential.state).to eq :failed
      referential.failed_at = nil
      expect(referential.state).to eq :pending
      referential.ready = true
      referential.failed_at = nil
      expect(referential.state).to eq :active
      referential.archived_at = Time.now
      expect(referential.state).to eq :archived
    end

    context "the scopes" do
      it "should filter the referentials" do
        referential = create :referential
        referential.pending!
        expect(Referential.pending).to include referential
        expect(Referential.failed).to_not include referential
        expect(Referential.active).to_not include referential
        expect(Referential.archived).to_not include referential

        referential = create :referential
        referential.failed!
        expect(Referential.pending).to_not include referential
        expect(Referential.failed).to include referential
        expect(Referential.active).to_not include referential
        expect(Referential.archived).to_not include referential

        referential = create :referential
        referential.active!
        expect(Referential.pending).to_not include referential
        expect(Referential.failed).to_not include referential
        expect(Referential.active).to include referential
        expect(Referential.archived).to_not include referential

        referential = create :referential
        referential.archived!
        expect(Referential.pending).to_not include referential
        expect(Referential.failed).to_not include referential
        expect(Referential.active).to_not include referential
        expect(Referential.archived).to include referential
      end
    end

    context 'pending_while' do
      it "should preserve the state" do
        referential = create :referential
        referential.archived!
        expect(referential.state).to eq :archived
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
      range = ref.metadatas.first.periodes.sample
      refs  = Referential.referential_ids_in_periode(range)
      expect(refs).to include(ref.id)
    end

    it 'should not retrieve referential id not in periode range' do
      range = Date.today - 2.year..Date.today - 1.year
      refs  = Referential.referential_ids_in_periode(range)
      expect(refs).to_not include(ref.id)
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
      Referential.new_from(ref, ref.workbench)
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
      ref
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
      expect(metadatas_attributes(clone)).to eq(metadatas_attributes(ref))
    end
  end

  describe "metadatas" do
    context "nested attributes support" do
      let(:attributes) do
        {
          "organisation_id" => first_organisation.id,
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
          "workbench_id"=>"1",
        }
      end

      let(:lines) { create_list(:line, 3)}

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

  context "lines" do
    describe "search" do
      it "should support Ransack search method" do
        expect(ref.lines.ransack.result.to_a).to eq(ref.lines.to_a)
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

      let(:context) { Chouette.create { referential } }
      let(:referential) { context.referential.reload }

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

end
