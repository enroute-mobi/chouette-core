require 'spec_helper'

RSpec.describe '/exports/index', :type => :view do

  let(:ref) { create :workbench_referential }
  let(:workbench) { assign :workbench, ref.workbench }
  let(:context) { { parent: workbench } }
  let(:exports) do
    assign :exports, build_paginated_collection(:export, ExportDecorator, referential: ref, workbench: workbench, type: "Export::Gtfs", context: context)
  end

  let!(:q) { assign :q, Ransack::Search.new(Export::Base) }
  let!(:types) { assign :types, [Export::Gtfs] }

  before(:each) do
    allow(view).to receive(:collection_name).and_return('exports')
    allow(view).to receive(:index_model).and_return(Export::Base)
    allow(view).to receive(:collection_path).and_return(workbench_exports_path(workbench))
    allow(view).to receive(:collection).and_return(exports)
    allow(view).to receive(:decorated_collection).and_return(exports)
    allow(view).to receive(:params).and_return(ActionController::Parameters.new(action: :index))
    allow(view).to receive(:parent).and_return(workbench)
    controller.request.path_parameters[:workbench_id] = workbench.id
    controller.request.path_parameters[:action] = "index"

  end

  context "referential name" do
    context "export with referential" do
      before(:each) do
        render
      end
      it "should have referential name on page" do
        exports.each_with_index do |export, index|
          ref_link = link_to(export.referential.name, href: referential_path(export.referential))
          expect(export.referential.present?).to be_truthy
          expect(rendered).to have_link(export.referential.name, href: referential_path(export.referential))
          expect(rendered).to have_link(export.name, href: workbench_export_path(workbench, export))
        end
      end
    end
    context "export without referential" do
      before(:each) do
        ref.destroy
        render
      end
      it "should not have show link(s) to redirect to show page" do
        exports.each_with_index do |export, index|
          expect(export.reload.referential.present?).to be_falsy
          expect(rendered).not_to have_link(ref.name, href: referential_path(ref.id))
          expect(rendered).to have_link(export.name, href: workbench_export_path(workbench, export))
          expect(rendered).to have_xpath("//tr[contains(@class,'base base-#{export.id}')]")
        end
      end
    end
  end
end
