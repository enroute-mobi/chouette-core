RSpec.describe NotificationRule::Email, type: :model do
	it { should validate_presence_of(:external_email) }

	describe '#recipients' do
		it 'should return a collection with only on user' do
			email = 'test@test.com'
			allow(subject).to receive(:external_email) { email }

			expect(subject.recipients.length).to eq(1)
			expect(subject.recipients.first).to be_a_kinf_of(User)
			expect(subject.recipients.first.email).to eq(email)
		end
	end
end
