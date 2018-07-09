require 'spec_helper'

describe Chouette::Line, :type => :model do
  subject { create(:line) }

  it { should belong_to(:line_referential) }
  # it { is_expected.to validate_presence_of :network }
  # it { is_expected.to validate_presence_of :company }
  it { should validate_presence_of :name }
  

  describe '#url' do
    it { should allow_value("http://foo.bar").for(:url) }
    it { should allow_value("https://foo.bar").for(:url) }
    it { should allow_value("http://www.foo.bar").for(:url) }
    it { should allow_value("https://www.foo.bar").for(:url) }
    it { should allow_value("www.foo.bar").for(:url) }
    it { should_not allow_value("foo.bar").for(:url) }
  end

  describe '#display_name' do
    it 'should display local_id, number, name and company name' do
      display_name = "#{subject.get_objectid.local_id} - #{subject.number} - #{subject.name} - #{subject.company.try(:name)}"
      expect(subject.display_name).to eq(display_name)
    end
  end

  # it { should validate_numericality_of :objectversion }

  # describe ".last_stop_areas_parents" do
  #
  #   it "should return stop areas if no parents" do
  #     line = create(:line_with_stop_areas)
  #     expect(line.stop_areas_last_parents).to eq(line.stop_areas)
  #   end
  #
  #   # it "should return stop areas parents if parents" do
  #   #   line = create(:line_with_stop_areas)
  #   #   route = create(:route, :line => line)
  #   #   parent = create(:stop_area)
  #   #   stop_areas = [ create(:stop_area),  create(:stop_area), create(:stop_area, :parent_id => parent.id) ]
  #   #   stop_areas.each do |stop_area|
  #   #     create(:stop_point, :stop_area => stop_area, :route => route)
  #   #   end
  #   #
  #   #   expect(line.stop_areas_last_parents).to match(line.stop_areas[0..(line.stop_areas.size - 2)].push(parent))
  #   # end
  #
  # end

  describe "#stop_areas" do
    let!(:route){create(:route, :line => subject)}
    it "should retreive route's stop_areas" do
      expect(subject.stop_areas.count).to eq(route.stop_points.count)
    end
  end

  context "#group_of_line_tokens=" do
    let!(:group_of_line1){create(:group_of_line)}
    let!(:group_of_line2){create(:group_of_line)}

    it "should return associated group_of_line ids" do
      subject.update_attributes :group_of_line_tokens => [group_of_line1.id, group_of_line2.id].join(',')
      expect(subject.group_of_lines).to include( group_of_line1)
      expect(subject.group_of_lines).to include( group_of_line2)
    end
  end

  describe "#update_attributes footnotes_attributes" do
    context "instanciate 2 footnotes without line" do
      let!( :footnote_first) {build( :footnote, :line_id => nil)}
      let!( :footnote_second) {build( :footnote, :line_id => nil)}
      it "should add 2 footnotes to the line" do
        subject.update_attributes :footnotes_attributes =>
          { Time.now.to_i => footnote_first.attributes,
            (Time.now.to_i-5) => footnote_second.attributes}
        expect(Chouette::Line.find( subject.id ).footnotes.size).to eq(2)
      end
    end
  end


end
