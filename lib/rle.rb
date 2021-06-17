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
    line = @f.first.chomp

    # skip comment lines
    while line[0] == "#"
      puts line
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

    # parse the pattern
    @f.each_char do |char|
      case char
      when /[[:digit:]]/
        count = (count * 10) + char.to_i
      when "b"
        count = 1 unless count.positive?
        x += count
        count = 0
      when "o"
        count = 1 unless count.positive?
        count.times do
          @figure.append({ x: x, y: y })
          x += 1
        end
        count = 0
      when "$"
        y += 1
        x = 0
        count = 0
      when "!"
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
