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
    }.to raise_error
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-BAND" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_band.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-MODE" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_mode.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-OPERATOR" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_operator.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-POWER" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_power.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-STATION" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_station.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-TIME" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_time.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-TRANSMITTER" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_transmitter.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error
  end

  it "should raise an error if an invalid value is given for key: CATEGORY-OVERLAY" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "category_overlay.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error
  end

  it "should raise an error if an invalid value is given for key: CLAIMED-SCORE" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "claimed_score.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error
  end

  it "should raise an error if an invalid value is given for key: CONTEST" do
    expect {
      invalid_file = File.join(File.dirname(__FILE__), 'data', 'invalid', "contest.cabrillo")
      log = Cabrillo.parse_file(invalid_file)
    }.to raise_error
  end

end
