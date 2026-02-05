# frozen_string_literal: true

describe Chouette::Line, type: :model do
  subject(:line) { context.line(:line) }

  let(:context) do
    Chouette.create do
      line :line
    end
  end

  it { should belong_to(:line_referential).required }
  # it { is_expected.to validate_presence_of :network }
  # it { is_expected.to validate_presence_of :company }
  it { should validate_presence_of :name }
  it { should have_many(:document_memberships) }
  it { should have_many(:documents) }

  it 'validates that transport mode and submode are matching' do
    subject.transport_mode = 'bus'
    subject.transport_submode = 'undefined'

    # BUS -> no submode = OK
    expect(subject).to be_valid

    # BUS -> bus specific submode = OK
    subject.transport_submode = 'nightBus'
    expect(subject).to be_valid

    # BUS -> rail specific submode = KO
    subject.transport_submode = 'regionalRail'
    expect(subject).not_to be_valid

    # RAIL -> rail specific submode = OK
    subject.transport_mode = 'rail'
    expect(subject).to be_valid

    # RAILS -> no submode = OK because we replace nil value by 'undefined'
    subject.transport_submode = nil
    expect(subject).to be_valid
  end

  describe '.with_transport_mode' do
    subject { described_class.with_chouette_transport_mode(transport_mode) }

    let!(:context) do
      Chouette.create do
        line :bus, transport_mode: 'bus', transport_submode: 'undefined'
        line :bus_night_bus, transport_mode: 'bus', transport_submode: 'nightBus'
      end
    end

    context 'with #bus' do
      let(:transport_mode) { Chouette::TransportMode.from('bus') }
      it { is_expected.to contain_exactly(context.line(:bus)) }
    end

    context 'with #bus/night_bus' do
      let(:transport_mode) { Chouette::TransportMode.from('bus/night_bus') }
      it { is_expected.to contain_exactly(context.line(:bus_night_bus)) }
    end

    context 'with #bus/bus' do
      let(:transport_mode) { Chouette::TransportMode.from('bus/bus') }
      it { is_expected.to be_empty }
    end
  end

  describe '#chouette_transport_mode' do
    subject { line.chouette_transport_mode.inspect }

    context 'with transport_mode "bus" and transport_submode "nightBus"' do
      before do
        line.transport_mode = 'bus'
        line.transport_submode = 'nightBus'
      end

      it { is_expected.to eq '#bus/night_bus' }
    end

    context 'with transport_mode "bus" and without transport_submode' do
      before do
        line.transport_mode = 'bus'
        line.transport_submode = nil
      end

      it { is_expected.to eq '#bus' }
    end

    context 'with transport_mode "bus" and transport_submode "undefined"' do
      before do
        line.transport_mode = 'bus'
        line.transport_submode = 'undefined'
      end

      it { is_expected.to eq '#bus' }
    end

    context 'when chouette_transport_mode is defined with a faulty value' do
      before do
        line.chouette_transport_mode = Chouette::TransportMode.new(:self_drive)
      end

      it { expect(line.valid?).to be false }
    end

    context 'when chouette_transport_mode is defined with a valid value' do
      before do
        line.chouette_transport_mode = Chouette::TransportMode.new(:bus)
      end

      it { expect(line.valid?).to be true }
    end
  end

  describe 'active scopes' do
    let!(:line1) { create :line, deactivated: false }
    let!(:line2) { create :line, deactivated: true }
    let!(:line3) { create :line, deactivated: false, active_from: '01/01/2000', active_until: '02/01/2000' }
    let!(:line4) { create :line, deactivated: false, active_until: '01/02/2000' }
    let!(:line5) { create :line, deactivated: false, active_from: '02/04/2000', active_until: '02/10/2000' }
    let!(:line6) { create :line, deactivated: false, active_from: '02/04/2000' }
    let!(:line7) { create :line, deactivated: false, active_from: '02/02/2000', active_until: '02/03/2000' }

    it 'should filter lines', skip: 'CHOUETTE-2813' do
      expect(Chouette::Line.activated).to match_array [line1, line3, line4, line5, line6, line7]
      expect(Chouette::Line.deactivated).to match_array [line2]
      expect(Chouette::Line.active_after('02/02/2000'.to_date)).to match_array [line1, line5, line6, line7]
      expect(Chouette::Line.active_before('02/02/2000'.to_date)).to match_array [line1, line3, line4]
      expect(Chouette::Line.not_active_after('02/02/2000'.to_date)).to match_array [line2, line3, line4]
      expect(Chouette::Line.not_active_before('02/02/2000'.to_date)).to match_array [line2, line5, line6, line7]
      expect(Chouette::Line.active_between('02/02/2000', '02/03/2000')).to match_array [line1, line7]
      expect(Chouette::Line.not_active_between('02/02/2000'.to_date,
                                               '02/03/2000'.to_date)).to match_array [line2, line3, line4, line5, line6]
    end
  end

  describe '#url' do
    it { should allow_value('http://foo.bar').for(:url) }
    it { should allow_value('https://foo.bar').for(:url) }
    it { should allow_value('http://www.foo.bar').for(:url) }
    it { should allow_value('https://www.foo.bar').for(:url) }
    it { should allow_value('www.foo.bar').for(:url) }
  end

  describe '#color' do
    ['012345', 'ABCDEF', '18FE23', '', nil].each do |c|
      it { should allow_value(c).for(:color) }
    end

    %w[01234 BCDEFG 18FE233].each do |c|
      it { should_not allow_value(c).for(:color) }
    end
  end

  describe '#text_color' do
    ['012345', 'ABCDEF', '18FE23', '', nil].each do |c|
      it { should allow_value(c).for(:color) }
    end

    %w[01234 BCDEFG 18FE233].each do |c|
      it { should_not allow_value(c).for(:color) }
    end
  end

  describe '#display_name' do
    subject { line.display_name }

    let(:context) do
      Chouette.create do
        company :company, name: 'enRoute'
        line :line, company: :company, name: 'Line 42', number: 'L42'
      end
    end

    it 'should display local_id, number, name and company name' do
      is_expected.to eq("#{line.get_objectid.short_id} - L42 - Line 42 - enRoute")
    end
  end

  describe '#code' do
    it 'uses objectid.local_id' do
      expect(subject.code).to eq(subject.get_objectid.local_id)
    end
  end

  describe '#stop_areas' do
    subject { line.stop_areas }

    let(:context) do
      Chouette.create do
        line :line
        stop_area :stop_area1
        stop_area :stop_area2
        referential lines: %i[line] do
          route line: :line, with_stops: false do
            stop_point stop_area: :stop_area1
            stop_point stop_area: :stop_area2
          end
        end
      end
    end
    let(:referential) { context.referential }
    let(:route) { context.route }

    before { referential.switch }

    it "should retreive route's stop_areas" do
      is_expected.to match_array(%i[stop_area1 stop_area2].map { |sa| context.stop_area(sa) })
    end
  end

  describe '#registration_number' do
    let(:first_line) { context.line(:first) }
    let(:second_line) { context.line(:second) }

    context 'when is an empty String' do
      let(:context) { Chouette.create { line } }
      let(:line) { context.line }

      it 'saved as nil' do
        line.registration_number = ''
        line.save!
        expect(line.reload).to have_attributes(registration_number: nil)
      end
    end

    context 'for two lines into two line providers' do
      let(:context) do
        Chouette.create do
          line_provider do
            line :first, registration_number: 'dummy'
          end
          line_provider do
            line :second
          end
        end
      end

      it 'can have the same value' do
        expect(second_line).to allow_value(first_line.registration_number).for(:registration_number)
      end
      it 'can be blank' do
        expect(second_line).to allow_value('').for(:registration_number)
      end
    end

    context 'for two lines into the same provider' do
      let(:context) do
        Chouette.create do
          line_provider do
            line :first, registration_number: 'dummy'
            line :second
          end
        end
      end

      it "can't have the same value" do
        expect(second_line).to_not allow_value(first_line.registration_number).for(:registration_number)
      end

      it 'can be blank' do
        expect(second_line).to allow_value('').for(:registration_number)
      end
    end
  end

  describe '#code_support' do
    let(:context) do
      Chouette.create do
        code_space short_name: 'test'
        line_provider do
          line :first
          line :second
        end
      end
    end

    let(:code_space) { context.code_space }
    let(:workbench) { context.workbench }
    let(:line_provider) { context.line_provider }
    let(:first_line) { context.line(:first) }

    let(:expected_code) do
      an_object_having_attributes({
                                    code_space: code_space,
                                    value: 'dummy'
                                  })
    end

    before do
      first_line.codes.create(code_space: code_space, value: 'dummy')
    end

    let(:line) { workbench.lines.by_code(code_space, 'dummy').first }

    it 'should create a line and find by code' do
      expect(line).to eq(first_line)
    end

    it 'should create and associate to codes' do
      expect(line.codes).to include(expected_code)
    end
  end

  describe '#update_unpermitted_blank_values' do
    let(:context) { Chouette.create { line } }
    let(:line) { context.line }

    it 'should force undefined value when transport_submode is nil' do
      line.transport_submode = nil
      line.save
      expect(line.transport_submode).to eq('undefined')
    end
  end

  describe '#active_from_less_than_active_until' do
    let(:subject) do
      line.validate
      line.errors.details[:active_until]
    end

    let(:line) do
      Chouette::Line.new(active_from: active_from, active_until: active_until)
    end

    context 'when active_until is greater active_from' do
      let(:active_from) { '2030-01-01'.to_date }
      let(:active_until) { '2030-10-01'.to_date }

      it { is_expected.to be_empty }
    end

    context 'when active_until and active_from are empty' do
      let(:active_from) { nil }
      let(:active_until) { nil }

      it { is_expected.to be_empty }
    end

    context 'when active_until is not empty and active_from is empty' do
      let(:active_from) { nil }
      let(:active_until) { '2030-10-01'.to_date }

      it { is_expected.to be_empty }
    end

    context 'when active_until is empty and active_from is not empty' do
      let(:active_from) { '2030-10-01'.to_date }
      let(:active_until) { nil }

      it { is_expected.to be_empty }
    end

    context 'when active_from is greater active_until' do
      let(:active_from) { '2030-09-01'.to_date }
      let(:active_until) { '2030-01-01'.to_date }

      it { is_expected.to eq([{ error: :active_from_less_than_active_until }]) }
    end
  end
end
