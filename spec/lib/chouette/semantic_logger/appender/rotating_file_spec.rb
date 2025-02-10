# frozen_string_literal: true

RSpec.describe Chouette::SemanticLogger::Appender::RotatingFile do
  subject(:appender) { described_class.new(file_name, **appender_args) }

  around do |example|
    Dir.mktmpdir("rspec-#{described_class.name}") do |dir|
      @tmp_dir = dir
      example.run
    end
  end
  attr_reader :tmp_dir

  def tmp_dir_content
    Dir["#{tmp_dir}/*"].map { |f| f[(tmp_dir.length + 1)..] }.sort
  end

  def build_log(message)
    SemanticLogger::Log.new('RSpec', :info, 2).tap { |log| log.assign(message: message) }
  end

  let(:file_name) { "#{tmp_dir}/test.log" }
  let(:formatter) { ->(log, _logger) { log.message.dup } }
  let(:reopen_max) { nil }
  let(:reopen_size) { nil }
  let(:appender_args) do
    {
      formatter: formatter
    }.tap do |h|
      h[:reopen_max] = reopen_max if reopen_max
      h[:reopen_size] = reopen_size if reopen_size
    end
  end

  describe '#log' do
    subject { appender.log(build_log(message)) }

    let(:message) { ('A' * 100).freeze }

    it 'creates the file' do
      expect { subject }.to change { tmp_dir_content }.from(%w[]).to(%w[test.log])
    end

    it 'appends message to the file' do
      subject
      expect(File.read(file_name)).to eq("#{message}\n")
    end

    context 'with reopen args' do
      let(:reopen_max) { 3 }
      let(:reopen_size) { 1000 }

      it 'creates the file' do
        expect { subject }.to change { tmp_dir_content }.from(%w[]).to(%w[test.log])
      end

      it 'writes message in the file' do
        subject
        expect(File.read(file_name)).to eq("#{message}\n")
      end

      context 'when the file already exists' do
        before do
          File.open(file_name, 'w') do |f|
            5.times do
              f.puts 'B' * 100
            end
          end
        end

        it 'does not create any new file' do
          expect { subject }.not_to change { tmp_dir_content }.from(%w[test.log])
        end

        it 'appends message to the file' do
          subject
          expect(File.read(file_name)).to start_with("#{'B' * 100}\n")
          expect(File.read(file_name)).to end_with("#{message}\n")
        end
      end

      context 'when the file already exists and is full' do
        context 'on opening' do
          before do
            File.open(file_name, 'w') do |f|
              10.times do
                f.puts 'B' * 100
              end
            end
          end

          it 'creates a new file' do
            expect { subject }.to(
              change { tmp_dir_content }.from(%w[test.log]).to(%w[test.log test.log.0])
            )
          end

          it 'writes message in the new file and keeps the old file unchanged' do
            old_message = File.read(file_name)
            subject
            expect(File.read(file_name)).to eq("#{message}\n")
            expect(File.read("#{file_name}.0")).to eq(old_message)
          end

          context 'with 1 other file' do
            before { FileUtils.touch("#{file_name}.0") }

            it 'creates a new file' do
              expect { subject }.to(
                change { tmp_dir_content }.from(%w[test.log test.log.0]).to(%w[test.log test.log.0 test.log.1])
              )
            end

            it 'writes message in the new file and keeps the old files unchanged' do
              old_message = File.read(file_name)
              subject
              expect(File.read(file_name)).to eq("#{message}\n")
              expect(File.read("#{file_name}.0")).to eq(old_message)
              expect(File.read("#{file_name}.1")).to be_empty
            end
          end

          context 'with max authorized number of files' do
            before do
              (reopen_max - 1).times do |i|
                FileUtils.touch("#{file_name}.#{i}")
              end
            end

            it 'creates a new file and deletes the oldest one' do
              expect { subject }.not_to change { tmp_dir_content }.from(%w[test.log test.log.0 test.log.1])
            end

            it 'writes message in the new file and keeps the old files unchanged' do
              old_message = File.read(file_name)
              subject
              expect(File.read(file_name)).to eq("#{message}\n")
              expect(File.read("#{file_name}.0")).to eq(old_message)
              expect(File.read("#{file_name}.1")).to be_empty
            end
          end
        end

        context 'after many calls do #log' do
          before do
            10.times do
              appender.log(build_log('B' * 100))
            end
          end

          it 'creates a new file' do
            expect { subject }.to(
              change { tmp_dir_content }.from(%w[test.log]).to(%w[test.log test.log.0])
            )
          end

          it 'writes message in the new file and keeps the old file unchanged' do
            old_message = File.read(file_name)
            subject
            expect(File.read(file_name)).to eq("#{message}\n")
            expect(File.read("#{file_name}.0")).to eq(old_message)
          end
        end
      end
    end
  end

  describe '#reopen' do
    subject { appender.reopen }

    before { expect(appender.file).to receive(:reopen) }

    it 'delegates #reopen to file' do
      subject
    end

    context 'when the file already exists and is full' do
      before do
        File.open(file_name, 'w') do |f|
          10.times do
            f.puts 'B' * 100
          end
        end

        it 'does not create a new file' do
          expect { subject }.not_to change { tmp_dir_content }.from(%w[test.log])
        end
      end
    end
  end

  describe '#flush' do
    subject { appender.flush }

    before { expect(appender.file.dev).to receive(:flush) }

    it 'delegates #flush to #file.dev' do
      subject
    end
  end
end
