require "rails_helper"

RSpec.describe ReferentialIndexSupport do
  after(:each) do
    ReferentialIndexSupport.reset!
  end

  let(:test_class) do
     child
     class TestClass < ActiveRecord::Base
       def self.table_name; 'referentials' end

       include ReferentialIndexSupport
       has_many_scattered :children
     end
  end

  let(:child) do
    class Child < ActiveRecord::Base
      include ReferentialIndexSupport
    end
  end

  it 'should raise an error when no reciproque relation is defined' do
    test_class
    expect{ TestClass.new.children }.to raise_error ReferentialIndexSupport::MissingReciproqueRelation
  end

  context 'with the reciproque relation' do
    let(:child) do
      class Child < ActiveRecord::Base
        include ReferentialIndexSupport
        belongs_to_public :test_class
      end
    end

    it 'should not raise an error' do
      expect{ test_class }.to_not raise_error
    end
  end
end
