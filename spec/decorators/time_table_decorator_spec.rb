require 'spec_helper'

describe TimeTableDecorator do
  let(:object) { build_stubbed :time_table, calendar: build_stubbed(:calendar) }
  let(:user) { build_stubbed :user }

  describe 'action links' do
    before do
      allow(helpers).to receive(:actualize_referential_time_table_path).and_return('/actualize_path')
      allow(helpers).to receive(:new_referential_time_table_time_table_combination_path).and_return('/combine_path')
      allow(helpers).to receive(:duplicate_referential_time_table_path).and_return('/duplicate_path')
      allow(helpers).to receive(:referential_time_table_path).and_return('/show_path')
      allow(helpers).to receive(:destroy_link_content).and_return('destroy_link_content')
    end

    context 'for authorized user' do
      before do
        stub_policy([actualize?: true, duplicate?: true, update?: true, destroy?: true])
      end

      it 'should render actualize link' do
        expect(subject.action_links.map(&:content)).to include(I18n.t('actions.actualize'))
        expect_action_link_hrefs.to include('/actualize_path')
      end

      it 'should render combine link' do
        expect(subject.action_links.map(&:content)).to include(I18n.t('actions.combine'))
        expect_action_link_hrefs.to include('/combine_path')
      end

      it 'should not render duplicate link' do
        expect(subject.action_links.map(&:content)).to include(I18n.t('actions.duplicate'))
        expect_action_link_hrefs.to include('/duplicate_path')
      end

      it 'should render destroy link' do
        expect(subject.action_links.map(&:content)).to include('destroy_link_content')
      end
    end

    context 'for unauthorized user' do
      before do
        stub_policy([actualize?: false, duplicate?: false, update?: false, destroy?: false])
      end

      it 'should not render actualize link' do
        expect(subject.action_links.map(&:content)).to_not include(I18n.t('actions.actualize'))
        expect_action_link_hrefs.to_not include('/actualize_path')
      end

      it 'should not render combine link' do
        expect(subject.action_links.map(&:content)).to_not include(I18n.t('actions.combine'))
        expect_action_link_hrefs.to_not include('/combine_path')
      end

      it 'should not render duplicate link' do
        expect(subject.action_links.map(&:content)).to_not include(I18n.t('actions.duplicate'))
        expect_action_link_hrefs.to_not include('/duplicate_path')
      end

      it 'should not render destroy link' do
        expect(subject.action_links.map(&:content)).to_not include('destroy_link_content')
      end
    end
  end
end
