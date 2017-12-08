require 'spec_helper'

describe ImportDecorator do
  let(:object) { build_stubbed :import }
  let(:user) { build_stubbed :user }

  describe 'action links' do
    before do
      allow(helpers).to receive(:workbench_import_path).and_return('/show_path')
      allow(helpers).to receive(:destroy_link_content).and_return('destroy_link_content')
    end

    context 'for authorized user' do
      before do
        stub_policy([destroy?: true])
      end

      it 'should render destroy link' do
        expect(subject.action_links.map(&:content)).to include('destroy_link_content')
      end
    end

    context 'for unauthorized user' do
      before do
        stub_policy([destroy?: false])
      end

      it 'should not render destroy link' do
        expect(subject.action_links.map(&:content)).to_not include('destroy_link_content')
      end
    end
  end
end
