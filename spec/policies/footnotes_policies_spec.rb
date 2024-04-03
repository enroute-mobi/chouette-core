RSpec.describe FootnotePolicy, type: :pundit_policy do

  let( :record ){ build_stubbed :footnote }

  permissions :edit_all? do
    it_behaves_like 'permitted policy and same organisation', 'footnotes.update', archived_and_finalised: true
  end

  permissions :destroy? do
    it_behaves_like 'permitted policy and same organisation', 'footnotes.destroy', archived_and_finalised: true
  end

  permissions :update_all? do
    it_behaves_like 'permitted policy and same organisation', 'footnotes.update', archived_and_finalised: true
  end

end
