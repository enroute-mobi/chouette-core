require 'spec_helper'

describe StopAreaDecorator do
  let(:object) { build_stubbed :stop_area }
  let(:user) { build_stubbed :user }

  describe 'action links' do
    before do
      allow(helpers).to receive(:new_stop_area_referential_stop_area_path).and_return('/new_path')
      allow(helpers).to receive(:edit_stop_area_referential_stop_area_path).and_return('/edit_path')
      allow(helpers).to receive(:stop_area_referential_stop_area_path).and_return('/show_path')
      allow(helpers).to receive(:destroy_link_content).and_return('destroy_link_content')
    end

    context 'for authorized user' do
      before do
        stub_policy([create?: true, update?: true, destroy?: true])
      end

      it 'should render create link' do
        expect(subject.action_links.map(&:content)).to include(I18n.t('stop_areas.actions.new'))
        expect_action_link_hrefs.to include('/new_path')
      end

      it 'should render edit link' do
        expect(subject.action_links.map(&:content)).to include(I18n.t('stop_areas.actions.edit'))
        expect_action_link_hrefs.to include('/edit_path')
      end

      it 'should render destroy link' do
        expect(subject.action_links.map(&:content)).to include('destroy_link_content')
      end
    end

    context 'for unauthorized user' do
      before do
        stub_policy([create?: false, update?: false, destroy?: false])
      end

      it 'should not render create link' do
        expect(subject.action_links.map(&:content)).to_not include(I18n.t('stop_areas.actions.new'))
        expect_action_link_hrefs.to_not include('/new_path')
      end

      it 'should not render edit link' do
        expect(subject.action_links.map(&:content)).to_not include(I18n.t('stop_areas.actions.edit'))
        expect_action_link_hrefs.to_not include('/edit_path')
      end

      it 'should not render destroy link' do
        expect(subject.action_links.map(&:content)).to_not include('destroy_link_content')
      end
    end
  end
end
