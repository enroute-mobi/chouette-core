describe Entrance, :type => :model do
  let(:context) do
    Chouette.create do
      entrance
    end
  end

  let(:subject) {context.entrance}

  it { should validate_presence_of(:name) }
  it { is_expected.to enumerize(:entrance_type) }
end
