#!/usr/bin/env ruby
# Cabrillo - Amateur Radio Log Library
#
# This library handles the parsing and generation of the Cabrillo ham radio
# logging format, commonly used by the ARRL for contesting. 
#
# Written by Ricky Elrod (github: @CodeBlock) and released an MIT license.
# https://www.github.com/CodeBlock/cabrillo-gem

$: << File.dirname(__FILE__)
require "contest_validators"
require 'date'
require 'time'

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

class InvalidDataError < StandardError; end

class Cabrillo
  @raise_on_invalid_data = true
  
  CABRILLO_VERSION = '3.0' # The current version of the spec, our default.
  
  # Public: Creates an instance of Cabrillo from a Hash of log data
  #
  # options - A Hash which contains data from a cabrillo log
  #
  # Returns an instance of Cabrillo.
  def initialize(options = {})
    # Let all the given entries automagically become instance variables.
    options.each do |key, value|
      instance_variable_set("@#{key}", value)
      this = class << self; self; end
      this.class_eval { attr_accessor key }
    end

    # Defaults and sanity checks can go here if they need to.
    @version = options[:version] || CABRILLO_VERSION
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
    attr_accessor :raise_on_invalid_data

    # Public: Parses a log (a string containing newlines) into a Cabrillo
    #         instance.
    #
    # log_contents - A String containing the entire to parse.
    #
    # TODO: Use a parsing lib like Treetop maybe?
    #
    # Returns an instance of Cabrillo.
    def parse(log_contents)
      cabrillo_info = Hash.new { |h,k| h[k] = [] }
      log_contents.lines.each do |line|
        line = line.strip

        # Ignore comments. (See README.md for info.)
        next if line.start_with? '#' or line.start_with? '//' or line.empty?

        # Info that can only appear once.
        cabrillo_info.merge! split_basic_line(line, 'START-OF-LOG', :version)
        cabrillo_info.merge! split_basic_line(line, 'CALLSIGN', :callsign)
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-ASSISTED', :category_assisted, ContestValidators::CATEGORY_ASSISTED)
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-BAND', :category_band, ContestValidators::CATEGORY_BAND)
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-MODE', :category_mode, ContestValidators::CATEGORY_MODE)
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-OPERATOR', :category_operator, ContestValidators::CATEGORY_OPERATOR)
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-POWER', :category_power, ContestValidators::CATEGORY_POWER)
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-STATION', :category_station, ContestValidators::CATEGORY_STATION)
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-TIME', :category_time, ContestValidators::CATEGORY_TIME)
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-TRANSMITTER', :category_transmitter, ContestValidators::CATEGORY_TRANSMITTER)
        cabrillo_info.merge! split_basic_line(line, 'CATEGORY-OVERLAY', :category_overlay, ContestValidators::CATEGORY_OVERLAY)
        cabrillo_info.merge! split_basic_line(line, 'CLAIMED-SCORE', :claimed_score, ContestValidators::CLAIMED_SCORE)
        cabrillo_info.merge! split_basic_line(line, 'CLUB', :club)
        cabrillo_info.merge! split_basic_line(line, 'CONTEST', :contest, ContestValidators::CONTEST)
        cabrillo_info.merge! split_basic_line(line, 'CREATED-BY', :created_by)
        cabrillo_info.merge! split_basic_line(line, 'EMAIL', :email)
        cabrillo_info.merge! split_basic_line(line, 'LOCATION', :location)
        cabrillo_info.merge! split_basic_line(line, 'NAME', :name)
        cabrillo_info.merge! split_basic_line(line, 'ADDRESS-CITY', :address_city)
        cabrillo_info.merge! split_basic_line(line, 'ADDRESS-STATE-PROVINCE', :address_state_province)
        cabrillo_info.merge! split_basic_line(line, 'ADDRESS-POSTALCODE', :address_postalcode)
        cabrillo_info.merge! split_basic_line(line, 'ADDRESS-COUNTRY', :address_country)

        # TODO: It would be great to remove some of the redundancy here.
        address = split_basic_line(line, 'ADDRESS', :address)
        cabrillo_info[:address] << address[:address] unless address.empty?

        soapbox = split_basic_line(line, 'SOAPBOX', :soapbox)
        cabrillo_info[:soapbox] << soapbox[:soapbox] unless soapbox.empty?

        club = split_basic_line(line, 'CLUB', :club)
        cabrillo_info[:club] << club[:club] unless club.empty?

        operators = split_basic_line(line, 'OPERATORS', :operators)
        cabrillo_info[:operators] << club[:operators] unless operators.empty?

        # If we already parsed in a contest then we're good. If not, we don't
        # know what to parse as, so skip.
        if line.start_with? "QSO: " and cabrillo_info[:contest]
          cabrillo_info[:qsos] << parse_qso(line, cabrillo_info[:contest])
        end
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

      if line_key == key
        okay = true
        unless validators.empty?
          okay = false
          validators.each do |v|
            okay = true and break if v.class.to_s == 'Regexp' and line_value =~ v
            okay = true and break if v.class.to_s == 'String' and line_value == v
          end
        end

        if okay || !@raise_on_invalid_data
          { hash_key => line_value.strip }
        elsif !validators.empty? && @raise_on_invalid_data
          raise InvalidDataError, "Invalid value given for key `#{line_key}`."
        end
      else
        { }
      end
    end

    # Private: Parses a QSO: line based on the contest type.
    #
    # qso_line - The Strnig containing the line of the logfile that we are
    #   parsing. Starts with "QSO:"
    # contest  - A String, the name of the contest that we are parsing.
    #
    # Returns a Hash containing the parsed result.
    def parse_qso(qso_line, contest)
      if @raise_on_invalid_data
        raise InvalidDataError, "Invalid contest: #{contest}" unless ContestValidators::CONTEST.include? contest
        raise InvalidDataError, "Line does not start with 'QSO: '" unless qso_line.start_with? "QSO: "
      end
      qso_line.gsub!(/^QSO: /, "")

      # Basic structure
      qso = {
        :exchange => {
          :sent     => {},
          :received => {}
        }
      }

      # In any and all cases, the first fields are: frequency, mode, date, time.
      # Store the exchange/everything else into an array (using splat) for
      #   later.
      qso[:frequency], qso[:mode], date, time, *exchange = qso_line.split
      
      # Parse the date and time into a Time object.
      qso[:time] = Time.parse(DateTime.strptime("#{date} #{time}", '%Y-%m-%d %H%M').to_s)

      # Transmitted callsign always comes first.
      qso[:exchange][:sent][:callsign] = exchange.shift

      # Parse the rest of the exchange
      case contest
      when 'CQ-160-CW', 'CQ-160-SSB', 'CQ-WPX-RTTY', 'CQ-WPX-CW', 'CQ-WPX-SSB', 'CQ-WW-RTTY', 'CQ-WW-CW', 'CQ-WW-SSB', 'ARRL-DX-CW', 'ARRL-DX-SSB', 'IARU-HF', 'ARRL-10', 'ARRL-160', 'JIDX-CW', 'JIDX-SSB', 'STEW-PERRY', 'OCEANIA-XD-CW', 'OCEANIA-DX-SSB', 'AP-SPRINT', 'NEQP', 'ARRL-FIELD-DAY'
        qso[:exchange][:sent][:rst] = exchange.shift
        qso[:exchange][:sent][:exchange] = exchange.shift

        qso[:exchange][:received][:callsign] = exchange.shift
        qso[:exchange][:received][:rst] = exchange.shift
        qso[:exchange][:received][:exchange] = exchange.shift
        qso[:exchange][:received][:transmitter_id] = exchange.shift
      when 'ARRL-SS-CW', 'ARRL-SS-SSB'
        qso[:exchange][:sent][:serial_number] = exchange.shift
        qso[:exchange][:sent][:precedence] = exchange.shift
        qso[:exchange][:sent][:check] = exchange.shift
        qso[:exchange][:sent][:arrl_section] = exchange.shift        

        qso[:exchange][:received][:callsign] = exchange.shift
        qso[:exchange][:received][:serial_number] = exchange.shift
        qso[:exchange][:received][:precedence] = exchange.shift
        qso[:exchange][:received][:check] = exchange.shift
        qso[:exchange][:received][:arrl_section] = exchange.shift
      end

      qso
    end

  end
end
