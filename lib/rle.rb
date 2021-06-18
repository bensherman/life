#!/usr/bin/env ruby

class RLE
  class FileError < RuntimeError; end

  class InvalidHeader < FileError; end

  class InvalidData < FileError; end

  def initialize(filename)
    @f = File.open(filename, "r")
    @figure = []
  end

  def validate_headers(headers)
    [2, 3].include?(headers.length) &&
      headers["x"].to_i.positive? &&
      headers["y"].to_i.positive? &&
      headers["rule"].to_s == headers["rule"]
  end

  def parse
    # RLE files are 3 parts.
    # 1. (optional) metadata, which starts with a # sign
    # 2. 3 key value pairs, like x=10, y=23, rule=B3/S23:
    #   a. (required) the width of the pattern (x)
    #   b. (required) the height of the pattern (y)
    #   c. (optional) the rule the pattern was made for. Conway's Game of Life is the default, which is refered
    #      to as the rule "b3/s23"

    # grab the first line for the first check.
    line = @f.first.chomp

    # skip metadata lines
    while line[0] == "#"
      line = @f.first.chomp
    end

    # get the header line
    headers = {}
    line.split(",").each do |params|
      k, v = params.split("=")
      headers[k.strip] = v.strip
    end

    raise InvalidHeader, "Invalid Header: #{headers}" unless validate_headers headers

    count = 0
    x = 0
    y = 0

    # parse the rest of the pattern
    @f.each_char do |char|
      case char
      when /[[:digit:]]/
        count = (count * 10) + char.to_i
      when "b" # dead cell
        count = 1 unless count.positive?
        x += count
        count = 0
      when "o" # live cell
        count = 1 unless count.positive?
        count.times do
          @figure.append({ x: x, y: y })
          x += 1
        end
        count = 0
      when "$" #  new line
        y += 1
        x = 0
        count = 0
      when "!" # end of pattern
        return @figure
      when "\r", "\n"
        next
      else
        raise InvalidData, "Invalid char in file: '#{char}'"
      end
    end
    @figure
  end
end
