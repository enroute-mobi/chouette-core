require 'spec_helper'

describe Chouette::LineNotice, :type => :model do
  subject { create(:line_notice) }
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

end
