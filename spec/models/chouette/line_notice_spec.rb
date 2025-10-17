# frozen_string_literal: true

RSpec.describe Chouette::LineNotice, type: :model do
  subject(:line_notice) { context.line_notice }

  let(:context) do
    Chouette.create do
      line_notice
    end
  end

  it { should validate_presence_of :title }

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
