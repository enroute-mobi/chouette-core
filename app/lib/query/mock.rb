# To be used to test how a (other) Query is built.
#
# See Search specs for samples.
#
#   let(:query) { Query::Mock.new(scope) }
#
#   before do
#     allow(Query::MyClass).to receive(:new).and_return(query)
#   end
#
#   it "uses Search name as text" do
#     search.name = "dummy"
#     expect(query).to receive(:text).with(search.name).and_return(query)
#     search.query
#   end

module Query
  class Mock < Base

    def method_missing(name, *args)
      self
    end

  end
end
