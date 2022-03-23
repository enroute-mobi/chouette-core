describe LocaleSelector do
	let(:context) { instance_double('Context', current_user: nil, params: nil, session: nil) }
	subject { LocaleSelector.new(context) }

	describe "#request_locale" do

		context "when params is not defined" do
			it 'should be nil' do
				expect(subject.request_locale).to be_nil
			end
		end

		context "when params[:lang] is not defined" do
			before { allow(subject).to receive(:params) { {} } }

			it 'should be nil' do
				expect(subject.request_locale).to be_nil
			end
		end

		context "when params[:lang] is a not supported locale" do
			before { allow(subject).to receive(:params) { { 'lang': 'dummy' } } }
				it 'should be nil' do
					expect(subject.request_locale).to be_nil
				end
		end

		context "when params[:lang] is 'fr'" do
			before { allow(subject).to receive(:params) { { 'lang': 'fr' } } }
				it "should be 'fr'" do
					expect(subject.request_locale).to be_nil
				end
		end
	end

	describe "#session_locale" do

		context "when session is not defined" do
			it 'should be nil' do
				expect(subject.session_locale).to be_nil
			end
		end

		context "when session[:language] is not defined" do
			before { allow(subject).to receive(:session) { {} } }

			it 'should be nil' do
				expect(subject.session_locale).to be_nil
			end
		end

		context "when session[:language] is a not supported locale" do
			before { allow(subject).to receive(:session) { { language: 'dummy' } } }
				it 'should be nil' do
					expect(subject.session_locale).to be_nil
				end
		end

		context "when session[:language] is 'fr'" do
			before { allow(subject).to receive(:session) { { language: 'fr' } } }
				it "should be 'fr'" do
					expect(subject.session_locale).to be_nil
				end
		end
	end

	describe "#user_locale" do

		context "when current_user is not defined" do
			it 'should be nil' do
				expect(subject.user_locale).to be_nil
			end
		end

		context "when current_user#user_locale is not defined" do
			before { allow(subject).to receive(:user) { instance_double('User', user_locale: nil) } }

			it 'should be nil' do
				expect(subject.user_locale).to be_nil
			end
		end

		context "when current_user#user_locale is a not supported locale" do
			before { allow(subject).to receive(:user) { instance_double('User', user_locale: 'dummy') } }
				it 'should be nil' do
					expect(subject.user_locale).to be_nil
				end
		end

		context "when current_user#user_locale is 'fr'" do
			before { allow(subject).to receive(:current_user) { instance_double('User', user_locale: 'fr') } }
				it "should be 'fr'" do
					expect(subject.user_locale).to be_nil
				end
		end
	end

	describe '#locale' do
		it 'should select locale by priority' do
			allow(subject).to receive(:request_locale) { 'fr' }
			allow(subject).to receive(:session_locale) { 'en' }
			allow(subject).to receive(:user_locale) { 'it' }
			allow(subject).to receive(:default_locale) { 'br' }
			expect(subject.locale).to eq('fr')

			allow(subject).to receive(:request_locale) { nil }
			expect(subject.locale).to eq('en')

			allow(subject).to receive(:session_locale) { nil }
			expect(subject.locale).to eq('it')

			allow(subject).to receive(:user_locale) { nil }
			expect(subject.locale).to eq('br')
		end
	end
end
