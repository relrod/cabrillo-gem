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
      cabrillo_info = {}
      log_contents.lines.each do |line|
        line = line.strip

        # Ignore comments. (See README.md for info.)
        next if line.start_with? '#' or line.start_with? '//' or line.empty?

        # Info that can only appear once.
        cabrillo_info.merge! split_basic_line(line, 'START-OF-LOG', :version)
        cabrillo_info.merge! split_basic_line(line, 'CREATED-BY', :created_by)
        cabrillo_info.merge! split_basic_line(line, 'CONTEST', :contest)
        cabrillo_info.merge! split_basic_line(line, 'CALLSIGN', :callsign)
        cabrillo_info.merge! split_basic_line(line, 'CLAIMED-SCORE', :claimed_score)
        cabrillo_info.merge! split_basic_line(line, 'CLUB', :club)
        cabrillo_info.merge! split_basic_line(line, 'NAME', :name)


        # SOAPBOX comments - they can appear multiple times.
        line_key, line_value = line.split(/:\s+/, 2)
        if line_key == 'SOAPBOX'
          if cabrillo_info[:soapbox]
            if cabrillo_info[:soapbox].class.to_s == 'String'
              cabrillo_info[:soapbox] = [cabrillo_info[:soapbox], line_value]
            else
              cabrillo_info[:soapbox] << line_value
            end
          else
            cabrillo_info[:soapbox] = line_value
          end
        end
      end

      # TODO
      # cabrillo_info[:contest] determines parsing format for QSO/QSC: lines.

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
    # Returns a Hash of {:hash_key => value_from_parsed_line} or nil if the key
    #   wasn't found.
    def split_basic_line(line, key, hash_key)
      line_key, line_value = line.split(/:\s+/, 2)
      
      case line_key
      when key
        { hash_key => line_value.strip }
      else
        { nil => nil }
      end
    end
  end
end
