#!/usr/bin/env ruby

require 'json'
require 'open-uri'
require 'nokogiri'

class RedditVideoDownloader
  def initialize(url)
    @url = url
    check_ffmpeg
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
    output_file = "reddit_video_#{Time.now.to_i}.mp4"
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

  def check_ffmpeg
    # This conditon will return a success code (0) if it is installed (echo $?),
    # and therefore this function will early return. Behold, a guard clause!
    # Otherwise, continues and exits with error.
    return if system('which ffmpeg > /dev/null 2>&1')

    puts 'Error: ffmpeg is required'
    exit 1
  end
end

# Usage
if ARGV.empty?
  puts "Usage: #{$0} <reddit-post-url>"
  exit 1
end

RedditVideoDownloader.new(ARGV[0]).download
