# coding: utf-8
RSpec.describe Chouette::Sync::LineNotice do

  describe Chouette::Sync::LineNotice::Netex do

    let(:context) do
      Chouette.create do
        line_referential
      end
    end

    let(:target) { context.line_referential }

    mattr_reader :created_id, default: 'FR1:Notice:C00188:'
    mattr_reader :updated_id, default: 'FR1:Notice:C00251:'

    let(:xml) do
      %{
        <notices>
          <Notice version="any" id="#{created_id}">
            <Name>First</Name>
            <Text>First text</Text>
            <TypeOfNoticeRef ref="LineNotice" />
          </Notice>
          <Notice version="any" id="#{updated_id}">
            <Name>Second</Name>
            <Text>Second text</Text>
            <TypeOfNoticeRef ref="LineNotice" />
          </Notice>
          <Notice version="any" id="empty">
            <Name></Name>
            <Text></Text>
            <TypeOfNoticeRef ref="LineNotice" />
          </Notice>
        </notices>
      }
    end

    let(:source) do
      Netex::Source.new.tap do |source|
        source.include_raw_xml = true
        source.parse StringIO.new(xml)
      end
    end

    subject(:sync) do
      Chouette::Sync::LineNotice::Netex.new source: source, target: target
    end

    let!(:updated_line_notice) do
      target.line_notices.create! name: 'Old Name', registration_number: updated_id
    end

    let(:created_line_notice) do
      line_notice created_id
    end

    def line_notice(registration_number)
      target.line_notices.find_by(registration_number: registration_number)
    end

    it "should create the LineNotice #{created_id}" do
      sync.synchronize

      expected_attributes = {
        title: 'First',
        content: 'First text'
      }
      expect(created_line_notice).to have_attributes(expected_attributes)
    end

    it "should update the #{updated_id}" do
      sync.synchronize

      expected_attributes = {
        title: 'Second',
        content: 'Second text'
      }
      expect(updated_line_notice.reload).to have_attributes(expected_attributes)
    end

    it 'should destroy Line Notices no referenced in the source' do
      useless_line_notice =
        target.line_notices.create! name: 'Useless', registration_number: 'unknown'
      sync.synchronize
      expect(target.line_notices.where(id:useless_line_notice)).to_not exist
    end

    it 'should create empty Line Notice' do
      sync.synchronize
      expect(target.line_notices.where(registration_number:"empty")).to_not exist
    end

  end

end
