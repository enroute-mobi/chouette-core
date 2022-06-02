RSpec.describe Document, type: :model do
  it { should belong_to(:document_type).required }
  it { should belong_to(:document_provider).required }
  it { should have_many :codes }
  it { should validate_presence_of :file }
  it { should validate_presence_of :validity_period }
  it { should validate_presence_of :document_type_id }
  it { should validate_presence_of :document_provider_id }

	it 'should validate validity_period' do
		document = Document.new

		document.validity_period = Range.new Date.today, Date.today + 1.day
		document.valid?
		expect(document.errors[:validity_period]).to be_empty

		document.validity_period = Range.new Date.today, nil
		document.valid?
		expect(document.errors[:validity_period]).to be_empty


		document.validity_period = Range.new nil, Date.today
		document.valid?
		expect(document.errors[:validity_period]).to be_empty

		document.validity_period = Range.new 1, 10
		document.valid?
		expect(document.errors.details[:validity_period]).to match_array([{ error: :no_bounds}])
	end
end
