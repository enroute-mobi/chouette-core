describe Referential, :type => :model do
  let(:ref) { create :workbench_referential, metadatas: [create(:referential_metadata)] }

  it { should have_many(:metadatas) }
  it { should belong_to(:workbench) }
  it { should belong_to(:referential_suite) }

  context "validation" do
    subject { build_stubbed(:referential) }

    it { should validate_presence_of(:objectid_format) }

    it 'should authorize slug with nummerical value' do
      subject.slug = '2018-hiver-jezequel-mm-lyon-nice'
      expect(subject).to be_valid
    end

    it 'should authorize slug with accents' do
      subject.slug = 'écolê-été-hiver-lyon-nice'
      expect(subject).to be_valid
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

  context "Cloning referential" do
    let(:clone) do
      Referential.new_from(ref, [])
    end

    # let(:saved_clone) do
    #   clone.tap do |clone|
    #     clone.organisation = ref.organisation
    #     clone.metadatas.each do |metadata|
    #       metadata.line_ids = ref.lines.where(id: clone.line_ids, objectid: JSON.parse(ref.organisation.sso_attributes["functional_scope"]).collect(&:id)
    #       metadata.periodes = metadata.periodes.map { |period| Range.new(period.end+1, period.end+10) }
    #     end
    #     clone.save!
    #   end
    # end

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
