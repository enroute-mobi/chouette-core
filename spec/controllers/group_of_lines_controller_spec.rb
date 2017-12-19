RSpec.describe GroupOfLinesController, type: :controller do
  
  login_user

  let( :line_referential ){ create :line_referential }

  context 'collection' do
    it_should_redirect_to_forbidden 'GET :index' do
      get :index, line_referential_id: line_referential.id
    end
  end

  context 'member' do 
    let( :group_of_line ){ create :group_of_line, line_referential: line_referential }

    it_should_redirect_to_forbidden 'GET :show' do
      get :show, line_referential_id: line_referential.id, id: group_of_line.id
    end
  end
end
