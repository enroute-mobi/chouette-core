
RSpec.describe StopAreaDecorator do

  let(:stop_area) { Chouette::StopArea.new }
  let(:decorator) { stop_area.decorate }

  describe '#waiting_time_text' do
    it "returns '-' when waiting_time is nil" do
      stop_area.waiting_time = nil
      expect(decorator.waiting_time_text).to eq('-')
    end

    it "returns '-' when waiting_time is zero" do
      stop_area.waiting_time = 0
      expect(decorator.waiting_time_text).to eq('-')
    end

    it "returns '120 minutes' when waiting_time is 120" do
      stop_area.waiting_time = 120
      expect(decorator.waiting_time_text).to eq('120 minutes')
    end
  end

end
