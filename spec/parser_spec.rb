require File.join(File.dirname(__FILE__), '..', 'lib', 'cabrillo')

describe Cabrillo do
  it "should parse a valid file" do
    valid_file = File.join(File.dirname(__FILE__), 'data', 'valid_log.cabrillo')
    log = Cabrillo.parse_file(valid_file)

    log.should be_an_instance_of(Cabrillo)
    log.to_hash.should be_an_instance_of(Hash)
    log.to_hash[:version].should == "3.0"
  end
end
