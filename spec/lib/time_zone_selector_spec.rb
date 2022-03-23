describe TimeZoneSelector do
	subject { TimeZoneSelector.new(nil, nil) }

	describe "#browser_time_zone" do

		context "when cookies is not defined" do
			it 'should be nil' do
				expect(subject.browser_time_zone).to be_nil
			end
		end

		context "when cookies[browser.timezone] is not defined" do
			before { allow(subject).to receive(:cookies) { {} } }

			it 'should be nil' do
				expect(subject.browser_time_zone).to be_nil
			end
		end

		context "when cookies[browser.timezone] is a not supported locale" do
			before { allow(subject).to receive(:cookies) { { 'browser.timezone': 'dummy' } } }
				it 'should be nil' do
					expect(subject.browser_time_zone).to be_nil
				end
		end

		context "when cookies[browser.timezone] is 'Paris'" do
			before { allow(subject).to receive(:cookies) { { 'browser.timezone': 'Paris' } } }
				it "should be 'Paris'" do
					expect(subject.browser_time_zone).to eq('Europe/Paris')
				end
		end
	end

	describe "#user_time_zone" do

		context "when current_user is not defined" do
			it 'should be nil' do
				expect(subject.user_time_zone).to be_nil
			end
		end

		context "when current_user#time_zone is not defined" do
			before { allow(subject).to receive(:user) { instance_double('User', time_zone: nil) } }

			it 'should be nil' do
				expect(subject.user_time_zone).to be_nil
			end
		end

		context "when current_user#time_zone is a not supported locale" do
			before { allow(subject).to receive(:user) { instance_double('User', time_zone: 'dummy') } }
				it 'should be nil' do
					expect(subject.user_time_zone).to be_nil
				end
		end

		context "when current_user#time_zone is 'Paris'" do
			before { allow(subject).to receive(:user) { instance_double('User', time_zone: 'Paris') } }
				it "should be 'Paris'" do
					expect(subject.user_time_zone).to eq('Europe/Paris')
				end
		end
	end

	describe '#time_zone' do
		it 'should select time_zone by priority' do
			# allow(subject).to receive(:browser_time_zone) { 'Paris' }
			allow(subject).to receive(:user_time_zone) { 'London' }
			allow(subject).to receive(:default_time_zone) { 'New York' }

			# expect(subject.time_zone).to eq('Paris')

			# allow(subject).to receive(:browser_time_zone) { nil }

			expect(subject.time_zone).to eq('London')

			allow(subject).to receive(:user_time_zone) { nil }

			expect(subject.time_zone).to eq('New York')
		end
	end
end
