#!/usr/bin/env ruby

# frozen_string_literal: true

require 'json'
require 'open-uri'
require 'nokogiri'
require 'optparse'
require 'fileutils'

class RedditVideoDownloader
  def initialize(url, options = {})
    @url = url
    check_ffmpeg
    @output_dir = ensure_path_exists(options[:path] ||
      File.expand_path('~/Downloads'))
  end

  def download
    # Get video data
    json_url = @url.chomp('/') + '.json'
    json_data = URI.open(json_url, 'User-Agent' => 'Ruby/3.4.0').read
    data = JSON.parse(json_data)[0]['data']['children'][0]['data']

    # 'is_video' => true in json if URL is video post
    return puts 'Not a video post' unless data['is_video']

    # Get video and audio URLs
    dash_url = data['media']['reddit_video']['dash_url']
    manifest = URI.open(dash_url).read
    doc = Nokogiri::XML(manifest)
    # Remove namespaces to fix xpath query
    doc.remove_namespaces!

    base_url = "https://v.redd.it/#{dash_url.split('/')[3]}/"
    # Highest quality video will be first video Representation in manifest
    video_url = base_url +
                doc.at_xpath("//Representation[@mimeType='video/mp4'][1]/BaseURL").text
    audio_url = base_url +
                doc.at_xpath("//Representation[@mimeType='audio/mp4']//BaseURL").text

    # Download video and audio
    URI.open(video_url) { |f| File.write('temp_video.mp4', f.read) }
    URI.open(audio_url) { |f| File.write('temp_audio.mp4', f.read) }

    # Combine files
    output_file = File.join(@output_dir, "reddit_video_#{Time.now.to_i}.mp4")
    system('ffmpeg', '-i', 'temp_video.mp4', '-i', 'temp_audio.mp4', '-c:v', 'copy',
           '-c:a', 'aac', output_file, '-y', %i[out err] => File::NULL)
    # Cleanup
    File.delete('temp_video.mp4', 'temp_audio.mp4')
    puts "Downloaded: #{output_file}"
  rescue StandardError => e
    puts "Error: #{e.message}"
    puts e.backtrace
  end

  private

  def ensure_path_exists(path)
    expanded_path = File.expand_path(path)

    unless Dir.exist?(expanded_path)
      begin
        FileUtils.mkdir_p(expanded_path)
      rescue StandardError => e
        puts "Error creating directory: #{e.message}"
        exit 1
      end
    end

    unless File.writable?(expanded_path)
      puts "Error: Directory #{expanded_path} is not writable."
      exit 1
    end

    expanded_path
  end

  def check_ffmpeg
    # This conditon will return a success code (0) if it is installed (echo $?),
    # and therefore this function will early return. Behold, a guard clause!
    # Otherwise, continues and exits with error.
    return if system('which ffmpeg > /dev/null 2>&1')

    puts 'Error: ffmpeg is required'
    exit 1
  end
end

cli_options = {}
OptionParser.new do |parser|
  parser.banner = "Usage: #{$PROGRAM_NAME} [options] <reddit-post-url>"

  parser.on('-p PATH', '--path=PATH',
            'Select output directory (default: ~/Downloads)') do |p|
    cli_options[:path] = p
  end

  parser.on('-h', '--help', 'Show this help message') do
    puts parser
    exit
  end
end.parse!

# Usage
if ARGV.empty?
  puts "Usage: #{$PROGRAM_NAME} <reddit-post-url>"
  exit 1
end

# Create downloader instance and download video
rvd = RedditVideoDownloader.new(ARGV[0], cli_options)
rvd.download
