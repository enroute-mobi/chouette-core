
describe 'layouts/application', type: :view do

  before(:each) do
    allow(view).to receive_messages :user_signed_in? => true
  end

  context "when Referential is a new record" do
     
    let(:referential) { Referential.new }

    it "should display referential name as title" #do
    #   render
    #   expect(rendered).not_to have_selector("h1")
    # end
                                          
  end

end
