#!/usr/bin/env ruby
require 'fileutils'

class Convert
  attr_writer :file, :output, :outdir
  attr_reader :aspect, :audio, :video

  PROFILE = {:lq => {:audio => "-ab 64k -ar 22050 -ac 1", :video => "-s vga", :quality => "-qscale 8"},
              :hq => {:audio => "-ab 128k -ar 44100 -ac 2", :video => "", :quality => "-sameq"},
              :aspect => {:normal => "4:3", :widescreen => "16:9"}
  }

  def initialize(file, aspect, profile)
    aspect = aspect.nil? ? :normal : aspect.sub(/--/, '').to_sym
    profile = profile.nil? ? :hq : profile.sub(/--/, '').to_sym
    @aspect = PROFILE[:aspect][aspect]
    @audio = PROFILE[profile][:audio]
    @video = PROFILE[profile][:video]
    @quality = PROFILE[profile][:quality]
    @file = file
    @outdir = "#{ENV['HOME']}/.converted/"
    @output = "#{@outdir}#{File.basename(file.sub(/\.\w{1,3}\z/, '.avi'))}"
  end

  def sometimes_create_output_dir!
    FileUtils.mkdir_p(@outdir)
  end

  def show_notification(return_value)
    message = return_value ? "successful" : "failed"
    system("notify-send 'Conversion' '#{message}\n#{File.basename(@file)}'")
  end

  def run
    sometimes_create_output_dir!
    result = system("ffmpeg -y -i #{@file} -acodec libmp3lame #{@audio} -aspect #{@aspect} #{@video} -vcodec libxvid #{@quality} -r 25 #{@output}")
    show_notification(result)
  end


end

aspect = ARGV.select {|a| a =~ /--(widescreen|normal)\z/}
aspect = aspect.empty? ? nil : aspect.first

profile = ARGV.select {|p| p =~ /--(\wq)\z/}
profile = profile.empty? ? nil : profile.first

filename = ARGV.select {|f| f =~ /\w+\.\w{1,3}\z/}
raise "Error: file required" if filename.empty?
filename = filename.first

convert = Convert.new(filename, aspect, profile)
convert.run

