
describe Chouette::Company, :type => :model do
  subject { create(:company) }
  it { should validate_presence_of :name }


  describe "#nullables empty" do
    it "should set null empty nullable attributes" do
      subject.default_contact_organizational_unit = ''
      subject.default_contact_operating_department_name = ''
      subject.code = ''
      subject.default_contact_phone = ''
      subject.default_contact_fax = ''
      subject.default_contact_email = ''
      subject.nil_if_blank
      expect(subject.default_contact_organizational_unit).to be_nil
      expect(subject.default_contact_operating_department_name).to be_nil
      expect(subject.code).to be_nil
      expect(subject.default_contact_phone).to be_nil
      expect(subject.default_contact_fax).to be_nil
      expect(subject.default_contact_email).to be_nil
    end
  end

  describe "#nullables non empty" do
    it "should not set null non epmty nullable attributes" do
      subject.default_contact_organizational_unit = 'a'
      subject.default_contact_operating_department_name = 'b'
      subject.code = 'c'
      subject.default_contact_phone = 'd'
      subject.default_contact_fax = 'z'
      subject.default_contact_email = 'r'
      subject.nil_if_blank
      expect(subject.default_contact_organizational_unit).not_to be_nil
      expect(subject.default_contact_operating_department_name).not_to be_nil
      expect(subject.code).not_to be_nil
      expect(subject.default_contact_phone).not_to be_nil
      expect(subject.default_contact_fax).not_to be_nil
      expect(subject.default_contact_email).not_to be_nil
    end
  end

end
