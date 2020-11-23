module SnaphostSpecHelper

  module Methods
    def set_invariant expr, val=nil
      val ||= expr
      chain = expr.split(".")
      method = chain.pop

      before(:each) do
        allow(eval(chain.join('.'))).to receive(method){ val }
      end
    end
  end

  def self.included into
    into.extend Methods
  end
end

RSpec.configure do |config|
  config.include SnaphostSpecHelper, type: :view
end


RSpec::Matchers.define :match_actions_links_snapshot do |name|
  match do |actual|
    @content = Capybara::Node::Simple.new(rendered).find('.page_header').native.inner_html
    expect(@content).to match_snapshot(name)
  end

  failure_message do |actual|
    out = ["Snapshots did not match."]
    snap_path = File.dirname(method_missing(:class).metadata[:file_path]) + "/__snapshots__/#{name}.snap"
    temp_path = Pathname.new "#{Rails.root}/tmp/__snapshots__/#{name}.failed.snap"
    FileUtils.mkdir_p temp_path.dirname
    tmp = File.new temp_path, "w"
    tmp.write @content
    tmp.close()
    expected = File.read snap_path
    out << "Expected: #{expected}"
    out << "Actual: #{@content}"
    out << "\n\n --- DIFF ---"
    out << differ.diff_as_string(@content, expected)
    out << "\n\n --- Previews : ---"
    out << "Expected: \n" + snapshot_url(snap: snap_path, layout: :actions_links)
    out << " \nActual:  \n" + snapshot_url(snap: tmp.path, layout: :actions_links)
    out.join("\n")
  end

  def snapshot_url snap:, layout:
    "http://localhost:3000/snap/?snap=#{CGI.escape(snap.to_s)}&layout=#{CGI.escape(layout.to_s)}"
  end

  def differ
    RSpec::Support::Differ.new(
        :object_preparer => lambda { |object| RSpec::Matchers::Composable.surface_descriptions_in(object) },
        :color => RSpec::Matchers.configuration.color?
    )
  end
end
