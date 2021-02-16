RSpec.describe I18nObserver, type: :observer do
	let(:observer) { I18nObserver.new }

	it 'should reset Chouette::AreaType cache' do
		expect(Chouette::AreaType).to receive(:reset_caches!)
		observer.i18n_locale_updated(:fr)
	end
end
