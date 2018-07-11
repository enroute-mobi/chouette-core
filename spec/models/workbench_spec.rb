require 'rails_helper'

RSpec.describe Workbench, :type => :model do
  it 'should have a valid factory' do
    expect(FactoryGirl.build(:workbench)).to be_valid
  end

  it { should validate_presence_of(:name) }
  it { should validate_presence_of(:organisation) }
  it { should validate_presence_of(:objectid_format) }

  it { should belong_to(:organisation) }
  it { should belong_to(:line_referential) }
  it { should belong_to(:stop_area_referential) }
  it { should belong_to(:workgroup) }
  it { should belong_to(:output).class_name('ReferentialSuite') }

  it { should have_many(:lines).through(:line_referential) }
  it { should have_many(:networks).through(:line_referential) }
  it { should have_many(:companies).through(:line_referential) }
  it { should have_many(:group_of_lines).through(:line_referential) }

  it { should have_many(:stop_areas).through(:stop_area_referential) }

  it do
    # This callback interferes with the validation test
    Workbench.skip_callback(:validation, :before, :initialize_output)

    should validate_presence_of(:output)

    Workbench.set_callback(:validation, :before, :initialize_output)
  end

  context '.lines' do
    let!(:ids) { ['STIF:CODIFLIGNE:Line:C00840', 'STIF:CODIFLIGNE:Line:C00086'] }
    let!(:organisation) { create :organisation, sso_attributes: { functional_scope: ids.to_json } }
    let(:workbench) { create :workbench, organisation: organisation }
    let(:lines){ workbench.lines }
    before do
      (ids + ['STIF:CODIFLIGNE:Line:0000']).each do |id|
        create :line, objectid: id, line_referential: workbench.line_referential
      end
    end
    context "with the default scope policy" do
      before do
        Workgroup.workbench_scopes_class = WorkbenchScopes::All
      end

      it 'should retrieve all lines' do
        expect(lines.count).to eq 3
      end
    end

    context "with a scope policy based on the sso_attributes" do
      before do
        Workgroup.workbench_scopes_class = Stif::WorkbenchScopes
      end

      it 'should filter lines based on my organisation functional_scope' do
        lines = workbench.lines
        expect(lines.count).to eq 2
        expect(lines.map(&:objectid)).to include(*ids)
      end
    end
  end

  context '.stop_areas' do
    let(:sso_attributes){{stop_area_providers: %w(blublublu)}}
    let!(:organisation) { create :organisation, sso_attributes: sso_attributes }
    let(:workbench) { create :workbench, organisation: organisation, stop_area_referential: stop_area_referential }
    let(:stop_area_provider){ create :stop_area_provider, objectid: "blublublu" }
    let(:stop_area_referential){ create :stop_area_referential }
    let(:stop){ create :stop_area, stop_area_referential: stop_area_referential }
    let(:stop_2){ create :stop_area, stop_area_referential: stop_area_referential }

    before(:each) do
      Workgroup.workbench_scopes_class = WorkbenchScopes::All
      stop
      stop_area_provider.stop_areas << stop_2
    end

    context 'with a functional_scope' do
      it 'should filter stops based on the stop_area_referential' do
        stops = workbench.stop_areas
        expect(stops.count).to eq 2
        expect(stops).to include stop_2
        expect(stops).to include stop
      end
    end

    context 'without a functional_scope' do
      it 'should filter stops based on the stop_area_referential' do
        stops = workbench.stop_areas
        expect(stops.count).to eq 2
        expect(stops).to include stop_2
        expect(stops).to include stop
      end
    end

    context "with a scope policy based on the sso_attributes" do
      before do
        Workgroup.workbench_scopes_class = Stif::WorkbenchScopes
      end

      it 'should filter lines based on my organisation stop_area_providers' do
        stops = workbench.stop_areas
        expect(stops.count).to eq 1
        expect(stops).to include stop_2
        expect(stops).to_not include stop
      end
    end
  end


  describe ".create" do
    it "must automatically create a ReferentialSuite when being created" do
      workbench = Workbench.create
      expect(workbench.output).to be_an_instance_of(ReferentialSuite)
    end

    it "must not overwrite a given ReferentialSuite" do
      referential_suite = create(:referential_suite)
      workbench = create(:workbench, output: referential_suite)

      expect(workbench.output).to eq(referential_suite)
    end
  end
end
