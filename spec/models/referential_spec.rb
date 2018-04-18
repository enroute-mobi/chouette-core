describe Referential, :type => :model do
  let(:ref) { create :workbench_referential, metadatas: [create(:referential_metadata)] }

  it { should have_many(:metadatas) }
  it { should belong_to(:workbench) }
  it { should belong_to(:referential_suite) }

  context "validation" do
    subject { build_stubbed(:referential) }

    it { should validate_presence_of(:objectid_format) }

    it "assign slug with a good format" do
      time_reference = double(now: 1234567890)

      conditions = {
        "2018-Hiver-Jezequel-MM-Lyon-Nice": "hiver_jezeque_1234567890",
        "2018-Hiver-Jezequel-23293MM-Lyon-Nice": "hiver_jezeque_1234567890",
        "-Hiver-Jezequel-MM-Lyon-Nice": "hiver_jezeque_1234567890",
        "Hiver-Jezequel-MM-Lyon-Nice": "hiver_jezeque_1234567890",
        "20179282": "referential_1234567890"
      }

      conditions.each do |name, expected_slug|
        ref = Referential.new name: name
        ref.assign_slug time_reference
        expect(ref.slug).to eq(expected_slug)
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

  context ".state" do
    it "should return the expected values" do
      referential = build :referential
      referential.ready = false
      expect(referential.state).to eq :pending
      referential.failed_at = Time.now
      expect(referential.state).to eq :failed
      referential.ready = true
      referential.failed_at = nil
      expect(referential.state).to eq :active
      referential.archived_at = Time.now
      expect(referential.state).to eq :archived
    end

    context "the scopes" do
      it "should filter the referentials" do
        referential = create :referential, ready: false
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
      referential = FactoryGirl.create :referential
      expect(referential.migration_count).to be ActiveRecord::Migrator.get_all_versions.count
      expect(referential.migration_count).to be > 300
    end

  end

  context "Cloning referential" do
    let(:clone) do
      Referential.new_from(ref, nil)
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
        expect(ref.lines.search.result.to_a).to eq(ref.lines.to_a)
      end
    end
  end

  context "to be referential_read_only or not to be referential_read_only" do
    let( :referential ){ build_stubbed( :referential ) }

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
end
