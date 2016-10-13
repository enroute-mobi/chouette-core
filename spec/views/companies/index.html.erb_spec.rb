require 'spec_helper'

describe "/companies/index", :type => :view do

  let!(:line_referential) { assign :line_referential, create(:line_referential) }
  let!(:companies) { assign :companies, Array.new(2) { create(:company, line_referential: line_referential) }.paginate  }
  let!(:search) { assign :q, Ransack::Search.new(Chouette::Company) }

  # Fixme #1795
  # it "should render a show link for each group" do
  #   render
  #   companies.each do |company|
  #     expect(rendered).to have_selector("a[href='#{view.line_referential_company_path(line_referential, company)}']")
  #   end
  # end

  # it "should render a link to create a new group" do
  #   render
  #   expect(view.content_for(:sidebar)).to have_selector(".actions a[href='#{new_line_referential_company_path(line_referential)}']")
  # end

end
