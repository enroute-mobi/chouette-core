RSpec.shared_examples 'it works with both checksums modes' do |label, operation, opts={}|
  change = opts.key?(:change) ? opts[:change] : true
  to_or_to_not = change ? :to : :to_not # that is the question
  context "With inline checksum updates" do
    around { |example| Chouette::ChecksumManager.inline{ example.run }}

    it label do
      expect { instance_exec(&operation) }.send(to_or_to_not, change {
        checksum_owner.reload if opts[:reload]
        checksum_owner.checksum
      })
      expect { checksum_owner.reload }.to_not change { checksum_owner.checksum }
      expect { checksum_owner.update_checksum_without_callbacks! }.to_not change { checksum_owner.reload.checksum }
      instance_exec(&opts[:more]) if opts[:more]
    end
  end
end
