RSpec.describe ZipService, type: :zip do

  let( :unzipper ){ described_class.new( zip_data, allowed_lines ) }
  subject { unzipper.subdirs }

  let( :allowed_lines ){ Set.new(%w{C00108 C00109}) }
  let( :zip_data ){ zip_archive.data }
  let( :zip_archive ){ make_zip zip_name, zip_content }

  context 'one, legal, referential' do
    let( :zip_name ){ 'one_referential_ok.zip' }
    let( :zip_content ){ first_referential_ok_data }

    it 'yields correct output' do
      subject.each do | subdir |
        expect_correct_subdir subdir, make_zip('expected.zip', first_referential_ok_data)
      end
    end
  end

  context 'two referentials' do
    let( :zip_name ){ 'two_referential_ok.zip' }
    let( :zip_content ){ first_referential_ok_data.merge( second_referential_ok_data ) }

    it 'raise an error' do
      expect{ subject.first }.to raise_error ZipService::TooManyDirectoriesError
    end
  end

  context 'one referential with a spurious directory' do
    let( :zip_name ){ 'one_referential_spurious.zip' }
    let( :zip_content ){ first_referential_spurious_data }

    it 'returns a not ok object' do
      expect_incorrect_subdir subject.first, expected_spurious: %w{SPURIOUS}
    end
  end

  context 'one referential without calendar' do
    let( :zip_name ){ 'one_referential_no_calendar.zip' }
    let( :zip_content ){ first_referential_no_calendar_data }

    it 'returns a not ok object' do
      expect_incorrect_subdir subject.first, expected_missing_calendar: true
    end
  end

  context 'one referential with an unparsable calendar' do
    let( :zip_name ){ 'one_referential_unparsable_calendar.zip' }
    let( :zip_content ){ first_referential_unparsable_calendar_data }

    it 'returns a not ok object' do
      expect_incorrect_subdir subject.first, expected_wrong_calendar: true
    end
  end

  context 'one referential with a foreign line' do
    let( :zip_name ){ 'one_referential_foreign.zip' }
    let( :zip_content ){ first_referential_foreign_data }

    it 'returns a not ok object' do
      expect_incorrect_subdir subject.first, expected_foreign_lines: %w{C00110}
    end
  end

  context 'one messed up' do
    let( :zip_name ){ 'one_messed_up.zip' }
    let( :zip_content ){ messed_up_referential_data }

    it 'returns a not ok object (all error information provided)' do
      expect_incorrect_subdir subject.first,
                                expected_foreign_lines: %w{C00110 C00111},
                                expected_spurious: %w{SPURIOUS1 SPURIOUS2}
    end

  end

  # Regression treated in #5281
  context 'one_first_level_dir' do
    let( :zip_data ){ File.read fixtures_path('regression-5281.zip') }
    let( :zip_name ){ 'regression_5281' }

    let( :allowed_lines ){
      Set.new([*164..168, 171].map{|line| "C00#{line}"})
    }

    let( :subdirs ){ subject.to_a }

    it 'returns one not ok object' do
      expect( subdirs.size ).to eq(1)
      expect( subdirs.first ).not_to be_ok
      expect( subdirs.first.spurious ).to eq(%w{OFFRE_SNTYO_1_20170820120001 OFFRE_SNTYO_2_20170820120001})
    end
  end

  # Behaviour
  # ---------
  def expect_correct_subdir subdir, expected_zip
    expect( subdir ).to be_ok
    expect( subdir.foreign_lines ).to be_empty
    expect( subdir.spurious ).to be_empty
    subdir.stream.tap do | stream |
      stream.rewind

      stream_content, expected_zip_content = [stream, StringIO.new(expected_zip.data)].map do |s|
        [].tap do |arr|
          Zip::InputStream.open(s) do |io|
            while (entry = io.get_next_entry) do
              arr << [entry.name, entry.size]
            end
          end
        end
      end

      expect(stream_content).to eq(expected_zip_content)
    end
  end

  def expect_incorrect_subdir subdir, expected_spurious: [], expected_foreign_lines: [], expected_missing_calendar: false, expected_wrong_calendar: false
    expect( subdir ).not_to be_ok
    expect( subdir.foreign_lines ).to eq(expected_foreign_lines)
    expect( subdir.spurious ).to eq(expected_spurious)
    expect( subdir.missing_calendar ).to eq(expected_missing_calendar)
    expect( subdir.wrong_calendar ).to eq(expected_wrong_calendar)
  end

  # Data
  # ----
  let :valid_calendar do
    """
    <netex:PublicationDelivery xmlns:netex=\"http://www.netex.org.uk/netex\">
      <netex:ValidBetween>
        <netex:FromDate>2017-03-01</netex:FromDate>
        <netex:ToDate>2017-03-31</netex:ToDate>
      </netex:ValidBetween>
    </netex:PublicationDelivery>
    """
  end

  let :wrong_calendar do
    """
    <netex:PublicationDelivery xmlns:netex=\"http://www.netex.org.uk/netex\">
      <netex:ValidBetween>
        <netex:FromDate>2017-03-01</netex:FromDate>
        <netex:ToDate>2017-13-31</netex:ToDate>
      </netex:ValidBetween>
    </netex:PublicationDelivery>
    """
  end

  let :first_referential_ok_data do
    {
       'Referential1/calendriers.xml'     => valid_calendar,
       'Referential1/commun.xml'          => 'common',
       'Referential1/offre_C00108_9.xml'  => 'line 108 ref 1',
       'Referential1/offre_C00109_10.xml' => 'line 109 ref 1'
    }
  end
  let :first_referential_foreign_data do
    {
       'Referential2/calendriers.xml'     => valid_calendar,
       'Referential2/commun.xml'          => 'common',
       'Referential2/offre_C00110_11.xml' => 'foreign line ref 1',
       'Referential2/offre_C00108_9.xml'  => 'line 108 ref 1',
       'Referential2/offre_C00109_10.xml' => 'line 109 ref 1'
    }
  end
  let :first_referential_spurious_data do
    {
       'Referential3/calendriers.xml'     => valid_calendar,
       'Referential3/commun.xml'          => 'common',
       'Referential3/SPURIOUS/commun.xml' => 'common',
       'Referential3/offre_C00108_9.xml'  => 'line 108 ref 1',
       'Referential3/offre_C00109_10.xml' => 'line 109 ref 1'
    }
  end
  let :second_referential_ok_data do
    {
       'Referential4/calendriers.xml'     => valid_calendar,
       'Referential4/commun.xml'          => 'common',
       'Referential4/offre_C00108_9.xml'  => 'line 108 ref 2',
       'Referential4/offre_C00109_10.xml' => 'line 109 ref 2'
    }
  end
  let :messed_up_referential_data do
    {
       'Referential5/calendriers.xml'      => valid_calendar,
       'Referential5/commun.xml'           => 'common',
       'Referential5/SPURIOUS1/commun.xml' => 'common',
       'Referential5/SPURIOUS2/commun.xml' => 'common',
       'Referential5/offre_C00110_11.xml'  => 'foreign line ref 1',
       'Referential5/offre_C00111_11.xml'  => 'foreign line ref 1',
       'Referential5/offre_C00108_9.xml'   => 'line 108 ref 1',
       'Referential5/offre_C00109_10.xml'  => 'line 109 ref 1'
    }
  end
  let :first_referential_no_calendar_data do
    {
       'Referential6/commun.xml'          => 'common',
       'Referential6/offre_C00108_9.xml'  => 'line 108 ref 1',
       'Referential6/offre_C00109_10.xml' => 'line 109 ref 1'
    }
  end
  let :first_referential_unparsable_calendar_data do
    {
       'Referential7/calendriers.xml'     => wrong_calendar,
       'Referential7/commun.xml'          => 'common',
       'Referential7/offre_C00108_9.xml'  => 'line 108 ref 1',
       'Referential7/offre_C00109_10.xml' => 'line 109 ref 1'
    }
  end


end
