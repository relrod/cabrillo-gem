require File.join(File.dirname(__FILE__), '..', 'lib', 'cabrillo')

describe Cabrillo do
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
end
