# frozen_string_literal: true

RSpec.describe Chouette::LineNotice, type: :model do
  subject(:line_notice) { context.line_notice }

  let(:context) do
    Chouette.create do
      line_notice
    end
  end

  it { should validate_presence_of :title }

  describe '.with_lines' do
    subject { described_class.with_lines(lines) }

    let(:context) do
      Chouette.create do
        line :line1
        line :line2
        line :line3
        line :line4
        line :line5
        line :line6

        line_notice :with_line1, lines: %i[line1]
        line_notice :with_line2, lines: %i[line2]
        line_notice :with_line3_1, lines: %i[line3] # rubocop:disable Naming/VariableNumber
        line_notice :with_line3_2, lines: %i[line3] # rubocop:disable Naming/VariableNumber
        line_notice :with_line4_and_line5, lines: %i[line4 line5]
      end
    end

    let(:lines) { Chouette::Line.where(id: %i[line2 line3 line4].map { |l| context.line(l) }) }

    it do
      is_expected.to match_array(
        %i[with_line2 with_line3_1 with_line3_2 with_line4_and_line5].map { |ln| context.line_notice(ln) } # rubocop:disable Naming/VariableNumber
      )
    end
  end

  describe '.with_vehicle_journeys' do
    subject { described_class.with_vehicle_journeys(vehicle_journeys) }

    let(:context) do
      Chouette.create do
        line_notice :with_vj1
        line_notice :with_vj2
        line_notice :with_vj3_1 # rubocop:disable Naming/VariableNumber
        line_notice :with_vj3_2 # rubocop:disable Naming/VariableNumber
        line_notice :with_vj4_and_vj5

        referential do
          vehicle_journey :vj1, line_notices: %i[with_vj1]
          vehicle_journey :vj2, line_notices: %i[with_vj2]
          vehicle_journey :vj3, line_notices: %i[with_vj3_1 with_vj3_2] # rubocop:disable Naming/VariableNumber
          vehicle_journey :vj4, line_notices: %i[with_vj4_and_vj5]
          vehicle_journey :vj5, line_notices: %i[with_vj4_and_vj5]
          vehicle_journey :vj6
        end
      end
    end

    let(:vehicle_journeys) do
      Chouette::VehicleJourney.where(id: %i[vj2 vj3 vj4].map { |l| context.vehicle_journey(l) })
    end

    before { context.referential.switch }

    it do
      is_expected.to match_array(
        %i[with_vj2 with_vj3_1 with_vj3_2 with_vj4_and_vj5].map { |ln| context.line_notice(ln) } # rubocop:disable Naming/VariableNumber
      )
    end
  end

  describe "#nullables empty" do
    it "should set null empty nullable attributes" do
      subject.content = ''
      subject.import_xml = ''
      subject.nil_if_blank
      expect(subject.content).to be_nil
      expect(subject.import_xml).to be_nil
    end
  end

  describe "#nullables non empty" do
    it "should not set null non empty nullable attributes" do
      subject.title = 'a'
      subject.content = 'b'
      subject.import_xml = 'c'
      subject.nil_if_blank
      expect(subject.title).not_to be_nil
      expect(subject.content).not_to be_nil
      expect(subject.import_xml).not_to be_nil
    end
  end

  describe '#unprotected' do
    context 'when line notice is not used' do
      it 'should return line notice' do
        expect(Chouette::LineNotice.unprotected).to include(line_notice)
        expect(line_notice).not_to be_protected
      end
    end

    context 'when line notice is used' do
      let(:context) do
        Chouette.create do
          line_notice

          referential do
            vehicle_journey
          end
        end
      end
      let(:referential) { context.referential }
      let(:vehicle_journey) { context.vehicle_journey }

      before do
        referential.switch
        vehicle_journey.update!(line_notices: [line_notice])
      end

      it 'should not return used notices' do
        expect(Chouette::LineNotice.unprotected).not_to include(line_notice)
        expect(line_notice).to be_protected
      end
    end
  end
end
