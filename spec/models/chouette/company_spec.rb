# frozen_string_literal: true

describe Chouette::Company, type: :model do
  subject { create(:company) }
  it { should validate_presence_of :name }
  it { is_expected.to have_many(:document_memberships) }
  it { is_expected.to have_many(:documents) }

  describe '#nullables empty' do
    it 'should set null empty nullable attributes' do
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

  describe '#nullables non empty' do
    it 'should not set null non epmty nullable attributes' do
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

  describe '#registration_number' do
    let(:first_company) { context.company(:first) }
    let(:second_company) { context.company(:second) }

    context 'for two companies into two company providers' do
      let(:context) do
        Chouette.create do
          line_provider do
            company :first, registration_number: 'dummy'
          end
          line_provider do
            company :second
          end
        end
      end

      it 'can have the same value' do
        expect(second_company).to allow_value(first_company.registration_number).for(:registration_number)
      end
      it 'can be blank' do
        expect(second_company).to allow_value('').for(:registration_number)
      end
    end

    context 'for two companies into the same provider' do
      let(:context) do
        Chouette.create do
          line_provider do
            company :first, registration_number: 'dummy'
            company :second
          end
        end
      end

      it "can't have the same value" do
        expect(second_company).to_not allow_value(first_company.registration_number).for(:registration_number)
      end

      it 'can be blank' do
        expect(second_company).to allow_value('').for(:registration_number)
      end
    end
  end

  describe '#referent' do
    let(:context) do
      Chouette.create do
        line_provider do
          company :first
          company :second, is_referent: true
        end
      end
    end

    let(:first_company) { context.company(:first) }
    let(:second_company) { context.company(:second) }

    subject { first_company }

    context 'when a company has a referent' do
      before { first_company.referent = second_company }

      it { is_expected.to be_valid }
    end

    context 'when a referent can not have a referent' do
      before do
        first_company.update is_referent: true
        first_company.referent = second_company
      end

      it { is_expected.not_to be_valid }

      describe '#errors' do
        subject { first_company.errors }
        before { first_company.validate }

        it { is_expected.to have_key(:referent_id) }
      end
    end

    context 'when a company used as referent must be flagged as referent' do
      before do
        second_company.update is_referent: false
        first_company.referent = second_company
      end

      it { is_expected.not_to be_valid }

      describe '#errors' do
        subject { first_company.errors }
        before { first_company.validate }

        it { is_expected.to have_key(:referent_id) }
      end
    end
  end

  describe '#fare_url' do
    let(:context) do
      Chouette.create do
        line_provider do
          company :company, fare_url: 'test.enroute.mobi'
        end
      end
    end

    let(:company) { context.company(:company) }

    subject { company.fare_url }

    it "company contains fare_url with the value 'test.enroute.mobi'" do
      is_expected.to eq('test.enroute.mobi')
    end
  end
end
