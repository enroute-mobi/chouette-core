# frozen_string_literal: true

RSpec.describe MetadataSupport do
  with_model :WithMetadata do
    table do |t|
      t.jsonb :metadata
    end

    model do
      include MetadataSupport

      has_metadata
    end
  end

  def assign_metadata(record, metadata)
    record.metadata = metadata
  end

  let(:record_metadata) { {} }
  let(:record) { WithMetadata.new.tap { |r| assign_metadata(r, record_metadata) } }

  after { Timecop.return }

  describe '.has_metadata?' do
    subject { WithMetadata.has_metadata? }

    it { is_expected.to eq(true) }
  end

  describe '#has_metadata?' do
    subject { record.has_metadata? }

    it { is_expected.to eq(true) }
  end

  describe '#merge_metadata_from' do
    subject { record.merge_metadata_from(source) }

    def assign_metadata(record, metadata)
      metadata.each do |k, v|
        record.metadata[k] = v
      end
    end

    let(:source_metadata) { {} }
    let(:source) { WithMetadata.new.tap { |r| assign_metadata(r, source_metadata) } }

    let(:record_metadata) { { 'creator_username' => 'john', 'modifier_username' => 'john' } }

    context 'when the source has no metadata' do
      it 'should do nothing' do
        expect { subject }.to(
          not_change { record.metadata.send(:table).slice(:creator_username, :modifier_username) }
        )
      end
    end

    context 'when the target has incomplete metadata' do
      let(:source_metadata) { { 'creator_username' => 'jane' } }

      before { record.metadata.delete_field(:creator_username_updated_at) }

      it 'should do nothing' do
        expect { subject }.to(
          not_change { record.metadata.send(:table).slice(:creator_username, :modifier_username) }
        )
      end
    end

    context 'when the source has older metadata' do
      let(:source_metadata) do
        {
          'creator_username' => 'jane',
          'modifier_username' => 'jane',
          'creator_username_updated_at' => 1.month.ago,
          'modifier_username_updated_at' => 1.month.ago
        }
      end

      it 'should do nothing' do
        expect { subject }.to(
          not_change { record.metadata.send(:table).slice(:creator_username, :modifier_username) }
        )
      end
    end

    context 'when the source has new metadata' do
      let(:record_metadata) do
        {
          'creator_username' => 'john',
          'modifier_username' => 'john',
          'creator_username_updated_at' => 1.month.ago,
          'modifier_username_updated_at' => 1.month.ago
        }
      end
      let(:source_metadata) { { 'creator_username' => 'jane', 'modifier_username' => 'jane' } }

      it 'should update metadata' do
        expect { subject }.to(
          change { record.metadata.send(:table) }.to({ creator_username: 'jane', modifier_username: 'jane' })
        )
      end
    end
  end

  describe '#metadata.initialize' do
    let(:time_value) { 1.day.ago.change(usec: 0) }
    let(:timestamp_value) { time_value }

    context 'when missing attribute is not a timestamp' do
      let(:record_metadata) { { creator_username: 'john' } }

      it 'sets attribute value' do
        expect(record.metadata.send(:table)[:creator_username]).to eq('john')
      end

      it 'does not set attribute timestamp' do
        expect(record.metadata.send(:table)).not_to have_key(:creator_username_updated_at)
      end

      it 'returns value through method' do
        expect(record.metadata.creator_username).to eq('john')
      end

      it 'returns timestamp value through method' do
        record.metadata.send(:table)[:creator_username_updated_at] = time_value
        expect(record.metadata.creator_username_updated_at).to eq(time_value)
      end

      it 'casts timestamp value through method' do
        record.metadata.send(:table)[:creator_username_updated_at] = time_value.as_json
        expect(record.metadata.creator_username_updated_at).to eq(time_value)
      end

      it 'does not cast timestamp value through method when its value is nil' do
        record.metadata.send(:table)[:creator_username_updated_at] = nil
        expect(record.metadata.creator_username_updated_at).to be_nil
      end

      context 'when initialized with a timestamp' do
        let(:record_metadata) { { creator_username: 'john', creator_username_updated_at: timestamp_value } }

        context 'encoded as a time' do
          it 'returns timestamp value through method' do
            expect(record.metadata.send(:table)[:creator_username_updated_at]).to eq(time_value.as_json)
          end
        end

        context 'encoded as a string' do
          let(:timestamp_value) { time_value.as_json }

          it 'returns timestamp value through method' do
            expect(record.metadata.send(:table)[:creator_username_updated_at]).to eq(time_value.as_json)
          end
        end

        context 'being nil' do
          let(:timestamp_value) { nil }

          it 'returns nil through method' do
            expect(record.metadata.send(:table)[:creator_username_updated_at]).to be_nil
          end
        end
      end
    end

    context 'when missing attribute is a timestamp' do
      let(:record_metadata) { { creator_username_updated_at: timestamp_value } }

      context 'encoded as a time' do
        it 'returns timestamp value through method' do
          expect(record.metadata.send(:table)[:creator_username_updated_at]).to eq(time_value.as_json)
        end

        it 'returns value through method' do
          expect(record.metadata.creator_username_updated_at).to eq(time_value)
        end
      end

      context 'encoded as a string' do
        let(:timestamp_value) { time_value.as_json }

        it 'returns timestamp value through method' do
          expect(record.metadata.send(:table)[:creator_username_updated_at]).to eq(time_value.as_json)
        end

        it 'returns value through method' do
          expect(record.metadata.creator_username_updated_at).to eq(time_value)
        end
      end

      context 'being nil' do
        let(:timestamp_value) { nil }

        it 'returns nil through method' do
          expect(record.metadata.send(:table)[:creator_username_updated_at]).to be_nil
        end

        it 'returns nil value through method' do
          expect(record.metadata.creator_username_updated_at).to be_nil
        end
      end
    end

    context 'when missing attribute is unknown' do
      subject { record.metadata.unknown }

      it { is_expected.to eq(nil) }

      it 'does not create new attributes' do
        expect { subject }.to(not_change { record.metadata.send(:table) })
      end

      it 'does not change record attributes to write' do
        expect { subject }.to(not_change { record.read_attribute(:metadata) })
      end
    end
  end

  describe '#metadata.as_json' do
    subject { record.metadata.as_json }

    context 'when init with symbols' do
      let(:record_metadata) { { a: 1, b: 2 } }

      it 'returns init attributes with string keys' do
        is_expected.to match({ 'a' => 1, 'b' => 2 })
      end
    end

    context 'when init with strings' do
      let(:record_metadata) { { 'a' => 1, 'b' => 2 } }

      it 'returns init attributes unchanged' do
        is_expected.to match({ 'a' => 1, 'b' => 2 })
      end
    end
  end

  describe '#metadata.method_missing' do
    describe '#metadata.b' do
      context 'when missing attribute is unknown' do
        subject { record.metadata.unknown }

        it { is_expected.to eq(nil) }

        it 'does not create new attributes' do
          expect { subject }.to(not_change { record.metadata.send(:table) })
        end
      end
    end

    describe '#metadata.b=' do
      context 'when attribute is not a timestamp' do
        subject { record.metadata.creator_username = 'john' }

        it 'sets attribute value' do
          expect { subject }.to change { record.metadata.send(:table)[:creator_username] }.from(nil).to('john')
        end

        it 'returns value through method' do
          expect { subject }.to change { record.metadata.creator_username }.from(nil).to('john')
        end

        it 'sets attribute timestamp' do
          expect { subject }.to(
            change { record.metadata.send(:table)[:creator_username_updated_at] }.from(nil).to(be_present)
          )
        end

        it 'returns timestamp value through method' do
          expect { subject }.to change { record.metadata.creator_username_updated_at }.from(nil).to(be_present)
        end

        it 'casts timestamp value through method' do
          subject
          time_value = 1.day.ago.to_time.change(usec: 0)
          record.metadata.send(:table)[:creator_username_updated_at] = time_value.as_json
          expect(record.metadata.creator_username_updated_at).to eq(time_value)
        end

        it 'does not cast timestamp value through method when its value is nil' do
          subject
          record.metadata.send(:table)[:creator_username_updated_at] = nil
          expect(record.metadata.creator_username_updated_at).to be_nil
        end

        it 'changes record attributes to write' do
          expect { subject }.to(
            change { record.read_attribute(:metadata) }.from({}).to(
              match({ 'creator_username' => 'john', 'creator_username_updated_at' => be_present })
            )
          )
        end

        context 'again after a while' do
          before do
            record.metadata.creator_username = 'jane'
            Timecop.travel(1.minute.from_now)
          end

          it 'sets attribute value' do
            expect { subject }.to change { record.metadata.send(:table)[:creator_username] }.from('jane').to('john')
          end

          it 'updates attribute timestamp' do
            expect { subject }.to(change { record.metadata.send(:table)[:creator_username_updated_at] })
          end

          it 'changes record attributes to write' do
            expect { subject }.to(change { record.read_attribute(:metadata) })
          end
        end
      end

      context 'when attribute is a timestamp' do
        subject { record.metadata.creator_username_updated_at = value }

        let(:time_value) { 1.minute.ago.to_time.change(usec: 0) }
        let(:value) { time_value }

        it 'sets attribute value' do
          expect { subject }.to(
            change { record.metadata.send(:table)[:creator_username_updated_at] }.from(nil).to(value)
          )
        end

        it 'returns value through method' do
          expect { subject }.to change { record.metadata.creator_username_updated_at }.from(nil).to(time_value)
        end

        it 'does not set attribute timestamp' do
          expect { subject }.to(
            not_change { record.metadata.send(:table)[:creator_username_updated_at_updated_at] }.from(nil)
          )
        end

        it 'casts value through method' do
          subject
          time_value = 1.day.ago.to_time.change(usec: 0)
          record.metadata.send(:table)[:creator_username_updated_at] = time_value.as_json
          expect(record.metadata.creator_username_updated_at).to eq(time_value)
        end

        it 'does not cast value through method when value is nil' do
          subject
          record.metadata.send(:table)[:creator_username_updated_at] = nil
          expect(record.metadata.creator_username_updated_at).to be_nil
        end

        it 'changes record attributes to write' do
          expect { subject }.to(
            change { record.read_attribute(:metadata) }.from({}).to(
              match({ 'creator_username_updated_at' => time_value.as_json })
            )
          )
        end

        context 'when value is a string' do
          let(:value) { time_value.as_json }

          it 'sets attribute value' do
            expect { subject }.to(
              change { record.metadata.send(:table)[:creator_username_updated_at] }.from(nil).to(value)
            )
          end

          it 'returns casted value through method' do
            expect { subject }.to change { record.metadata.creator_username_updated_at }.from(nil).to(time_value)
          end
        end

        context 'again after a while' do
          before do
            record.metadata.creator_username_updated_at = Time.zone.now
            Timecop.travel(1.minute.from_now)
          end

          it 'sets attribute value' do
            expect { subject }.to(change { record.metadata.send(:table)[:creator_username_updated_at] })
          end

          it 'changes record attributes to write' do
            expect { subject }.to(change { record.read_attribute(:metadata) })
          end
        end
      end
    end
  end

  describe '#metadata.[]=' do
    context 'when attribute is not a timestamp' do
      subject { record.metadata[:creator_username] = 'john' }

      it 'sets attribute value' do
        expect { subject }.to change { record.metadata.send(:table)[:creator_username] }.from(nil).to('john')
      end

      it 'returns value through method' do
        expect { subject }.to change { record.metadata.creator_username }.from(nil).to('john')
      end

      it 'sets attribute timestamp' do
        expect { subject }.to(
          change { record.metadata.send(:table)[:creator_username_updated_at] }.from(nil).to(be_present)
        )
      end

      it 'returns timestamp value through method' do
        expect { subject }.to change { record.metadata.creator_username_updated_at }.from(nil).to(be_present)
      end

      it 'casts timestamp value through method' do
        subject
        time_value = 1.day.ago.to_time.change(usec: 0)
        record.metadata.send(:table)[:creator_username_updated_at] = time_value.as_json
        expect(record.metadata.creator_username_updated_at).to eq(time_value)
      end

      it 'does not cast timestamp value through method when its value is nil' do
        subject
        record.metadata.send(:table)[:creator_username_updated_at] = nil
        expect(record.metadata.creator_username_updated_at).to be_nil
      end

      it 'changes record attributes to write' do
        expect { subject }.to(
          change { record.read_attribute(:metadata) }.from({}).to(
            match({ 'creator_username' => 'john', 'creator_username_updated_at' => be_present })
          )
        )
      end

      context 'again after a while' do
        before do
          record.metadata[:creator_username] = 'jane'
          Timecop.travel(1.minute.from_now)
        end

        it 'sets attribute value' do
          expect { subject }.to change { record.metadata.send(:table)[:creator_username] }.from('jane').to('john')
        end

        it 'updates attribute timestamp' do
          expect { subject }.to(change { record.metadata.send(:table)[:creator_username_updated_at] })
        end

        it 'changes record attributes to write' do
          expect { subject }.to(change { record.read_attribute(:metadata) })
        end

        it 'setter updates attribute timestamp' do
          expect { record.metadata.creator_username = 'john' }.to(
            change { record.metadata.send(:table)[:creator_username_updated_at] }
          )
        end

        it 'setter changes record attributes to write' do
          expect { record.metadata.creator_username = 'john' }.to(change { record.read_attribute(:metadata) })
        end
      end
    end

    context 'when attribute is a timestamp' do
      subject { record.metadata[:creator_username_updated_at] = value }

      let(:time_value) { 1.minute.ago.to_time.change(usec: 0) }
      let(:value) { time_value }

      it 'sets attribute value' do
        expect { subject }.to change { record.metadata.send(:table)[:creator_username_updated_at] }.from(nil).to(value)
      end

      it 'returns value through method' do
        expect { subject }.to change { record.metadata.creator_username_updated_at }.from(nil).to(time_value)
      end

      it 'does not set attribute timestamp' do
        expect { subject }.to(
          not_change { record.metadata.send(:table)[:creator_username_updated_at_updated_at] }.from(nil)
        )
      end

      it 'casts value through method' do
        subject
        time_value = 1.day.ago.to_time.change(usec: 0)
        record.metadata.send(:table)[:creator_username_updated_at] = time_value.as_json
        expect(record.metadata.creator_username_updated_at).to eq(time_value)
      end

      it 'does not cast value through method when value is nil' do
        subject
        record.metadata.send(:table)[:creator_username_updated_at] = nil
        expect(record.metadata.creator_username_updated_at).to be_nil
      end

      it 'changes record attributes to write' do
        expect { subject }.to(
          change { record.read_attribute(:metadata) }.from({}).to(
            match({ 'creator_username_updated_at' => time_value.as_json })
          )
        )
      end

      context 'when value is a string' do
        let(:value) { time_value.as_json }

        it 'sets attribute value' do
          expect { subject }.to(
            change { record.metadata.send(:table)[:creator_username_updated_at] }.from(nil).to(value)
          )
        end

        it 'returns casted value through method' do
          expect { subject }.to change { record.metadata.creator_username_updated_at }.from(nil).to(time_value)
        end
      end

      context 'again after a while' do
        before do
          record.metadata[:creator_username_updated_at] = Time.zone.now
          Timecop.travel(1.minute.from_now)
        end

        it 'sets attribute value' do
          expect { subject }.to(change { record.metadata.send(:table)[:creator_username_updated_at] })
        end

        it 'changes record attributes to write' do
          expect { subject }.to(change { record.read_attribute(:metadata) })
        end

        it 'setter changes record attributes to write' do
          expect { record.metadata.creator_username_updated_at = Time.zone.now }.to(
            change { record.read_attribute(:metadata) }
          )
        end
      end
    end
  end

  describe '#metadata.each' do
    let(:record_metadata) { { a: 1, b: 2 } }

    it { expect { |b| record.metadata.each(&b) }.to yield_successive_args([:a, 1], [:b, 2]) }
  end

  it 'should set the correct values on save' do
    Timecop.freeze(Time.zone.now) do
      record.metadata.creator_username = 'john.doe'
      record.save!
      copy = WithMetadata.find(record.id)
      expect(copy.metadata.creator_username).to eq('john.doe')
      expect(copy.metadata.creator_username_updated_at.strftime('%Y-%m-%d %H:%M:%S.%3N')).to(
        eq(Time.zone.now.strftime('%Y-%m-%d %H:%M:%S.%3N'))
      )
    end
  end

  it 'should set the correct values on update' do
    Timecop.freeze(Time.zone.now) do
      record.save!
      id = record.id
      copy1 = WithMetadata.find(id)
      copy1.set_metadata!(:creator_username, 'john.doe')
      copy2 = WithMetadata.find(id)
      expect(copy2.metadata.creator_username).to eq('john.doe')
      expect(copy2.metadata.creator_username_updated_at.strftime('%Y-%m-%d %H:%M:%S.%3N')).to(
        eq(Time.zone.now.strftime('%Y-%m-%d %H:%M:%S.%3N'))
      )
    end
  end
end
