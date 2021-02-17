RSpec.shared_examples_for 'Chouette::Safe method' do |method|
	it 'should call Chouette::Safe#execute' do
		allow(Chouette::Safe).to receive(:execute).with(kind_of(String))
		expect(Chouette::Safe).to receive(:execute)

		resource.send(method)
	end

	context 'when the method throws an error' do
		it 'should be captured by Chouette::Safe' do
			expect(Chouette::Safe).to receive(:capture)
			allow(Chouette::Safe).to receive(:_execute).and_raise('Error')

			resource.send(method)
		end
	end
end
