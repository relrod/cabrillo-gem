#!/usr/bin/env ruby
# Cabrillo - Amateur Radio Log Library
#
# This library handles the parsing and generation of the Cabrillo ham radio
# logging format, commonly used by the ARRL for contesting. 
#
# Written by Ricky Elrod (github: @CodeBlock) and released an MIT license.
# https://www.github.com/CodeBlock/cabrillo-gem

# TODO: Split these into their own gem because they are handy. :-)
class String
  def to_hz
    freq_split = self.split('.')
    hertz = freq_split[0].to_i * 1000000 # MHz

    # Handle KHz
    if not freq_split[1].nil?
      freq_split[1] += '0' while freq_split[1].length < 3
      hertz += freq_split[1].to_i * 1000 # KHz
    end

    # Handle Hz
    if not freq_split[2].nil?
      freq_split[2] += '0' while freq_split[2].length < 3
      hertz += freq_split[2].to_i # Hz
    end
    hertz
  end
end

class Integer
  def to_mhz
    self.to_s.reverse.gsub(/(.{3})(?=.)/, '\1.\2').reverse
  end
end
# END TODO

class Cabrillo
  CABRILLO_VERSION = '3.0' # The current version of the spec, our default.
  
  def initialize(options = {})
    @version       = options[:version] || CABRILLO_VERSION
    @created_by    = options[:created_by]
    @contest       = options[:contest]
    @callsign      = options[:callsign]
    @claimed_score = options[:claimed_score]
    @club          = options[:club]
    @name          = options[:name]
    @soapbox       = options[:soapbox]
  end

  # Public: Return the collected data as a Hash.
  #
  # Returns the data that was parsed (or given) as a Hash.
  def to_hash
    h = {}
    self.instance_variables.each do |variable|
      h[variable[1..-1].to_sym] = self.instance_variable_get(variable)
    end
    h
  end

  class << self
    # Public: Parses a log (a string containing newlines) into a Cabrillo
    #         instance.
    #
    # log_contents - A String containing the entire to parse.
    #
    # TODO: Use a parsing lib like Treetop maybe?
    #
    # Returns an instance of Cabrillo.
    def parse(log_contents)
      cabrillo_info = Hash.new []
      log_contents.lines.each do |line|
        line = line.strip

        # Ignore comments. (See README.md for info.)
        next if line.start_with? '#' or line.start_with? '//' or line.empty?

        # Info that can only appear once.
        cabrillo_info.merge! split_basic_line(line, 'START-OF-LOG', :version)
        cabrillo_info.merge! split_basic_line(line, 'CALLSIGN', :callsign)
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-ASSISTED', :category_assisted, ['ASSISTED', 'NON-ASSISTED'])
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-BAND', :category_band, ['ALL', '160M', '80M', '40M', '20M', '15M', '10M', '6M', '2M', '222', '432', '902', '1.2G', '2.3G', '3.4G', '5.7G', '10G', '24G', '47G', '75G', '119G', '142G', '241G', 'Light'])
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-MODE', :category_mode, ['SSB', 'CW', 'RTTY', 'MIXED'])
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-OPERATOR', :category_operator, ['SINGLE-OP', 'MULTI-OP', 'CHECKLOG'])
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-POWER', :category_power, ['HIGH', 'LOW', 'QRP'])
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-STATION', :category_station, ['FIXED', 'MOBILE', 'PORTABLE', 'ROVER', 'EXPEDITION', 'HQ', 'SCHOOL'])
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-TIME', :category_time, ['6-HOURS', '12-HOURS', '24-HOURS'])
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-TRANSMITTER', :category_transmitter, ['ONE', 'TWO', 'LIMITED', 'UNLIMITED', 'SWL'])
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-OVERLAY', :category_overlay, ['ROOKIE', 'TB-WIRED', 'NOVICE-TECH', 'OVER-50'])
        cabrillo_info.merge! split_basic_line(line, 'CLAIMED-SCORE', :claimed_score, [/\d+/])
        cabrillo_info.merge! split_basic_line(line, 'CLUB', :club)
        cabrillo_info.merge! split_basic_line(line, 'CONTEST', :contest, ['AP-SPRINT', 'ARRL-10', 'ARRL-160', 'ARRL-DX-CW', 'ARRL-DX-SSB', 'ARRL-SS-CW', 'ARRL-SS-SSB', 'ARRL-UHF-AUG', 'ARRL-VHF-JAN', 'ARRL-VHF-JUN', 'ARRL-VHF-SEP', 'ARRL-RTTY', 'BARTG-RTTY', 'CQ-160-CW', 'CQ-160-SSB', 'CQ-WPX-CW', 'CQ-WPX-RTTY', 'CQ-WPX-SSB', 'CQ-VHF', 'CQ-WW-CW', 'CQ-WW-RTTY', 'CQ-WW-SSB', 'DARC-WAEDC-CW', 'DARC-WAEDC-RTTY', 'DARC-WAEDC-SSB', 'FCG-FQP', 'IARU-HF', 'JIDX-CW', 'JIDX-SSB', 'NA-SPRINT-CW', 'NA-SPRINT-SSB', 'NCCC-CQP', 'NEQP', 'OCEANIA-DX-CW', 'OCEANIA-DX-SSB', 'RDXC', 'RSGB-IOTA', 'SAC-CW', 'SAC-SSB', 'STEW-PERRY', 'TARA-RTTY'])
        cabrillo_info.merge! split_basic_line(line, 'CREATED-BY', :created_by)
        cabrillo_info.merge! split_basic_line(line, 'EMAIL', :email)
        cabrillo_info.merge! split_basic_line(line, 'LOCATION', :location)
        cabrillo_info.merge! split_basic_line(line, 'NAME', :name)
        cabrillo_info.merge! split_basic_line(line, 'ADDRESS', :address)
        cabrillo_info.merge! split_basic_line(line, 'ADDRESS-CITY', :address_city)
        cabrillo_info.merge! split_basic_line(line, 'ADDRESS-STATE-PROVINCE', :address_state_province)
        cabrillo_info.merge! split_basic_line(line, 'ADDRESS-POSTALCODE', :address_postalcode)
        cabrillo_info.merge! split_basic_line(line, 'ADDRESS-COUNTRY', :address_country)


        # TODO
        # cabrillo_info[:contest] determines parsing format for QSO/QSC: lines.
      end
      Cabrillo.new(cabrillo_info)
    end

    # Public: A wrapper to Cabrillo.parse() to parse a log from a file.
    #
    # file_path - The path to the logfile to parse.
    #
    # Returns what Cabrillo.parse() returns, an instance of Cabrillo.
    def parse_file(file_path)
      Cabrillo.parse(IO.read(file_path))
    end


    private
    # Private: Parses a specific line of the log, in most cases.
    #
    # line     - The String of log line to parse.
    # key      - The key to look for in the line.
    # hash_key - The key to use in the resulting Hash.
    #
    # Throws an Exception if validators are given but the data does not match
    #   one of them.
    #
    # Returns a Hash of {:hash_key => value_from_parsed_line} or nil if the key
    #   wasn't found.
    def split_basic_line(line, key, hash_key, validators = [])
      line_key, line_value = line.split(/:\s+/, 2)

      case line_key
      when key
        okay = true
        unless validators.empty?
          okay = false
          validators.each do |v|
            okay = true and break if v.class.to_s == 'Regexp' and line_value =~ v
            okay = true and break if v.class.to_s == 'String' and line_value == v
          end
        end

        if okay
          { hash_key => line_value.strip }
        elsif !validators.empty?
          raise "Invalid value given for key `#{line_key}`."
        end
      else
        { nil => nil }
      end
    end
  end
end
