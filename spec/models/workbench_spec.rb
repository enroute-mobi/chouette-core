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
  it { should have_many(:notification_rules).dependent(:destroy) }

  it do
    # This callback interferes with the validation test
    Workbench.skip_callback(:validation, :before, :initialize_output, raise: false)

    should validate_presence_of(:output)

    Workbench.set_callback(:validation, :before, :initialize_output)
  end

  context 'aggregation setup' do
    context 'locked_referential_to_aggregate' do
      let(:workbench) { create(:workbench) }

      it 'should be nil by default' do
        expect(workbench.locked_referential_to_aggregate).to be_nil
      end

      it 'should only take values from the workbench output' do
        referential = create(:referential)
        workbench.locked_referential_to_aggregate = referential
        expect(workbench).to_not be_valid
        referential.referential_suite = workbench.output
        expect(workbench).to be_valid
      end

      it 'should not log a warning if the referential exists' do
        referential = create(:referential)
        referential.referential_suite = workbench.output
        workbench.update locked_referential_to_aggregate: referential
        expect(Rails.logger).to_not receive(:warn)
        expect(workbench.locked_referential_to_aggregate).to eq referential
      end

      it 'should log a warning if the referential does not exist anymore' do
        workbench.update_column :locked_referential_to_aggregate_id, Referential.last.id.next
        expect(Rails.logger).to receive(:warn)
        expect(workbench.locked_referential_to_aggregate).to be_nil
      end
    end

    context 'referential_to_aggregate' do
      let(:workbench) { create(:workbench) }
      let(:referential) { create(:referential) }
      let(:latest_referential) { create(:referential) }

      before(:each) do
        referential.update referential_suite: workbench.output
        latest_referential.update referential_suite: workbench.output
        workbench.output.update current: latest_referential
      end

      it 'should point to the current output' do
        expect(workbench.referential_to_aggregate).to eq latest_referential
      end

      context 'when designated a referential_to_aggregate' do
        before do
          workbench.update locked_referential_to_aggregate: referential
        end

        it 'should use this referential instead' do
          expect(workbench.referential_to_aggregate).to eq referential
        end
      end
    end
  end

  context "normalize_prefix" do
    it "should ensure the resulting prefix is valid" do
      workbench = create(:workbench)
      ["aaa ", "aaa-bbb", "aaa_bbb", "aaa bbb", " aaa bb ccc"].each do |val|
        workbench.update_column :prefix, nil
        workbench.prefix = val
        expect(workbench).to be_valid
        workbench.update_column :prefix, nil
        expect(workbench.update(prefix: val)).to be_truthy
      end
    end
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
        allow(Workgroup).to receive(:workbench_scopes_class).and_return(WorkbenchScopes::All)
      end

      it 'should retrieve all lines' do
        expect(lines.count).to eq 3
      end
    end

  end

  context '.stop_areas' do
    let(:sso_attributes){{stop_area_providers: %w(blublublu)}}
    let!(:organisation) { create :organisation, sso_attributes: sso_attributes }
    let(:workbench) { create :workbench, organisation: organisation, stop_area_referential: stop_area_referential }
    let(:stop_area_provider){ create :stop_area_provider, objectid: "FR1:OrganisationalUnit:blublublu:", stop_area_referential: stop_area_referential }
    let(:stop_area_referential){ create :stop_area_referential }
    let(:stop){ create :stop_area, stop_area_referential: stop_area_referential }
    let(:stop_2){ create :stop_area, stop_area_referential: stop_area_referential }

    before(:each) do
      stop
      stop_area_provider.stop_areas << stop_2
      stop_area_provider.save
    end

    context 'without a functional_scope' do
      before do
        allow(Workgroup).to receive(:workbench_scopes_class).and_return(WorkbenchScopes::All)
      end

      it 'should filter stops based on the stop_area_referential' do
        stops = workbench.stop_areas
        expect(stops.count).to eq 2
        expect(stops).to include stop_2
        expect(stops).to include stop
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
