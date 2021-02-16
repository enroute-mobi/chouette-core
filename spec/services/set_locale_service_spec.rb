RSpec.describe SetLocaleService, type: :service do

	it 'should broadcast an event' do
		expect { SetLocaleService.call(:fr) }.to broadcast(:i18n_locale_updated, :fr)
	end

	context 'when the wanted locale is included in the available locales list' do
		it 'should properly set the locale' do
			I18n.available_locales.each do |l|
				SetLocaleService.call(l)
				expect(I18n.locale).to eq(l)
			end
		end
	end

	context 'when not' do
		it 'should set the locale to the default one' do
			SetLocaleService.call('test')
			expect(I18n.locale).to eq(I18n.default_locale)
		end
	end
end
