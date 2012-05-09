require File.join(File.dirname(__FILE__), '..', 'lib', 'cabrillo')

describe Cabrillo do
  before(:each) { Cabrillo.raise_on_invalid_data = true }

  it "should parse a valid file" do
    valid_file = File.join(File.dirname(__FILE__), 'data', 'valid_log.cabrillo')
    log = Cabrillo.parse_file(valid_file)

    log.should be_an_instance_of(Cabrillo)
    hashified_log = log.to_hash

    hashified_log.should be_an_instance_of(Hash)

    hashified_log[:version].should == "3.0"
    log.version.should == "3.0"

    hashified_log[:callsign].should == "W8UPD"
    log.callsign.should == "W8UPD"

    hashified_log[:address].should be_an_instance_of(Array)
    log.address.should be_an_instance_of(Array)

    hashified_log[:address].first.should == "501 Zook Hall"
    log.address.first.should == "501 Zook Hall"

    hashified_log[:soapbox].should be_an_instance_of(Array)
    log.soapbox.should be_an_instance_of(Array)

    log.soapbox.size.should == 2
    hashified_log[:soapbox].size.should == 2
  end

  it "should properly parse common details out of QSO: lines" do
    valid_file = File.join(File.dirname(__FILE__), 'data', 'valid_log.cabrillo')
    log = Cabrillo.parse_file(valid_file)
    log.qsos.size.should == 3
    log.qsos.first[:mode].should == "PH"
    log.qsos.first[:frequency].should == "14325"
    log.qsos.first[:time].should be_an_instance_of(Time)
    log.qsos.keep_if { |q| q[:exchange][:sent][:callsign] == 'N8SQL' }.size.should == 3
  end

  it "should handle parsing QSO: lines somewhat fast" do
    started_at = Time.now.to_i
    valid_file = File.join(File.dirname(__FILE__), 'data', 'long_log.cabrillo')
    log = Cabrillo.parse_file(valid_file)
    ended_at = Time.now.to_i
    log.qsos.size.should == 75

    # Should be able to parse 75 QSOs in under 1 second.
    (ended_at - started_at).should be < 1
  end

  it "should not raise an error on invalid data, if told not to." do
    expect {
      Cabrillo.raise_on_invalid_data = false
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_assisted.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
      log.version.should == "3.0"
      log.category_assisted.should == "INVALID-DATA"
    }.to_not raise_error
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-ASSISTED" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_assisted.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error(InvalidDataError)
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-BAND" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_band.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error(InvalidDataError)
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-MODE" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_mode.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error(InvalidDataError)
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-OPERATOR" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_operator.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error(InvalidDataError)
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-POWER" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_power.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error(InvalidDataError)
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-STATION" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_station.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error(InvalidDataError)
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-TIME" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_time.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error(InvalidDataError)
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-TRANSMITTER" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_transmitter.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error(InvalidDataError)
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-OVERLAY" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_overlay.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error(InvalidDataError)
  end

  it "should raise an error if an invalid value is given for key: CLAIMED-SCORE" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "claimed_score.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error(InvalidDataError)
  end

  it "should raise an error if an invalid value is given for key: CONTEST" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "contest.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error(InvalidDataError)
  end

  it "should parse NEQP (and similar) QSO lines successfully" do
    valid_file = File.join(File.dirname(__FILE__), 'data', 'valid_log.cabrillo')
    log = Cabrillo.parse_file(valid_file)
    log.qsos.size.should == 3
    log.qsos.first[:mode].should == "PH"
    log.qsos.first[:frequency].should == "14325"
    log.qsos.first[:time].should be_an_instance_of(Time)
    log.qsos.first[:exchange][:sent][:callsign].should == "N8SQL"
    log.qsos.first[:exchange][:sent][:rst].should == "59"
    log.qsos.first[:exchange][:sent][:exchange].should == "001"
    log.qsos.first[:exchange][:received][:callsign].should == "KG4SGP"
    log.qsos.first[:exchange][:received][:rst].should == "59"
    log.qsos.first[:exchange][:received][:exchange].should == "HARCT"
  end

end
