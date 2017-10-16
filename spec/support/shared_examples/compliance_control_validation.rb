RSpec.shared_examples_for 'has min_max_values' do

  context "is valid" do
    it 'if no value is provided' do
      expect_it.to be_valid
    end
    it 'if minimum is provided alone' do
      subject.minimum = 42
      expect_it.to be_valid
    end
    it 'if maximum is provided alone' do
      subject.maximum = 42
      expect_it.to be_valid
    end

    it 'if maximum is not smaller than minimum' do
      100.times do
        min = random_int
        max = min + random_int(20)
        subject.assign_attributes maximum: max, minimum: min
        subject.assign_attributes maximum: min, minimum: min
        expect_it.to be_valid
      end
    end
  end

  context "is invalid" do
    it 'if maximum is smaller than minimum' do
      100.times do
        min = random_int
        max = min - random_int(20) - 1
        subject.assign_attributes maximum: max, minimum: min
        expect_it.not_to be_valid
      end
    end

    it 'and has a correct error message' do
      subject.assign_attributes maximum: 1, minimum: 2
      expect_it.not_to be_valid
        expect( subject.errors.messages[:min_max_values].first ).to match("la valeur de minimum (2) ne doit pas être superieur à la valuer du maximum (1)")
    end
  end
end
