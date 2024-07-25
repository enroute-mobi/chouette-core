RSpec.describe UrlValidator do
  include Shoulda::Matchers::ActiveModel

  describe 'validates schema is dummy' do
    with_model :model do
      table do |t|
        t.string :url
      end

      model do
        validates :url, url: { scheme: 'dummy' }
      end
    end

    subject { Model.new }

    it { is_expected.to allow_value('dummy://example.com').for(:url) }
    it { is_expected.to_not allow_value('http://example.com').for(:url).with_message(:invalid_scheme, values: { expected_schemes: 'dummy' }) }
  end

  describe 'validates host is example.com' do
    with_model :model do
      table do |t|
        t.string :url
      end

      model do
        validates :url, url: { host: 'example.com' }
      end
    end

    subject { Model.new }

    it { is_expected.to allow_value('dummy://example.com').for(:url) }
    it { is_expected.to allow_value('http://example.com').for(:url) }
    it { is_expected.to_not allow_value('http://google.com').for(:url).with_message(:host_not_allowed, values: { expected_host: 'example.com' }) }
  end

  describe 'validates host is not private' do
    with_model :model do
      table do |t|
        t.string :url
      end

      model do
        validates :url, url: { private_host: false }
      end
    end

    subject { Model.new }

    it { is_expected.to allow_value('dummy://example.com').for(:url) }
    it { is_expected.to_not allow_value('dummy://localhost').for(:url).with_message(:private_host_not_allowed) }
    it { is_expected.to_not allow_value('dummy://127.0.0.1').for(:url) }
    it { is_expected.to_not allow_value('dummy://192.168.0.1').for(:url) }
  end
end
