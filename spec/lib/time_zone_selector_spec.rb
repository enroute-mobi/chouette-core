describe TimeZoneSelector do
	let(:context) { instance_double('Context', current_user: nil, cookies: nil) }
	subject { TimeZoneSelector.new(context) }

	describe "#request_time_zone" do

		context "when cookies is not defined" do
			it 'should be nil' do
				expect(subject.request_time_zone).to be_nil
			end
		end

		context "when cookies[browser.timezone] is not defined" do
			before { allow(subject).to receive(:cookies) { {} } }

			it 'should be nil' do
				expect(subject.request_time_zone).to be_nil
			end
		end

		context "when cookies[browser.timezone] is a not supported locale" do
			before { allow(subject).to receive(:cookies) { { 'browser.timezone': 'dummy' } } }
				it 'should be nil' do
					expect(subject.request_time_zone).to be_nil
				end
		end

		context "when cookies[browser.timezone] is 'Paris'" do
			before { allow(subject).to receive(:cookies) { { 'lang': 'Paris' } } }
				it "should be 'Paris'" do
					expect(subject.request_time_zone).to be_nil
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
					expect(subject.user_time_zone).to eq('Paris')
				end
		end
	end
end
