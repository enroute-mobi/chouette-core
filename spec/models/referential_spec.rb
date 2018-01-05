describe Referential, :type => :model do
  let(:ref) { create :workbench_referential, :with_metadatas }
  let(:context) { Chouette::Line.all.pluck(:objectid) }

  it { should have_many(:metadatas) }
  it { should belong_to(:workbench) }
  it { should belong_to(:referential_suite) }

  def check_data_are_consistent(ref)
    ref.switch
    remaining_line_ids = ref.metadatas.pluck(:line_ids).flatten
    Chouette::Route.all.each do |route|
      expect(remaining_line_ids).to include(route.line_id)
    end
    Chouette::VehicleJourney.all.each do |vj|
      expect(remaining_line_ids).to include(vj.route.line_id)
    end
  end

  context "validation" do
    subject { build_stubbed(:referential) }

    it { should validate_presence_of(:objectid_format) }
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
      Referential.new_from(ref, context) do |r|
        r.organisation = ref.organisation
        r.workbench = ref.workbench
        r.metadatas.first.lines.pop
        periode = r.metadatas.first.periodes.first
        periode = (periode.end+1.day..periode.end+2.day)
        r.metadatas.first.periodes = [periode]
      end
    end

    before(:each) do
      allow_any_instance_of(Referential).to receive(:clone_schema) do |this|
        ReferentialCloning.create(source_referential: this.created_from, target_referential: this).clone!
      end
    end

    it "should preserve the data consistency" do
      expect(ref.lines.pluck(:objectid).sort).to eq context.sort
      clone.save!
      check_data_are_consistent(clone)
      check_data_are_consistent(ref)
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

  context 'with data' do
    before(:each) do
      ref.switch
      Chouette::Line.all.each do |line|
        route = create(:route, line: line)
        pattern = create(:journey_pattern, route: route)
        create(:vehicle_journey, journey_pattern: pattern)
      end
      check_data_are_consistent(ref)
    end

    context "after a metadata deletion" do
      it "should ensure the data are coherent" do
        expect(ref).to receive(:did_update_metadatas).and_call_original
        ref.metadatas = []
        check_data_are_consistent(ref)
      end
    end

    context "after a change in the metadatas" do
      it "should ensure the data are coherent" do
        expect(ref).to receive(:did_update_metadatas).and_call_original
        m = ref.metadatas.first
        m.lines = m.lines[0..0]
        m.save!

        check_data_are_consistent(ref)
      end
    end
  end
end
