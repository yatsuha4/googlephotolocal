require 'open-uri'
require 'openssl'
require_relative 'auth'
require_relative 'photos'

#
class Downloader
  #
  def initialize(dir)
    @dir = dir
    @cache = Hash.new
    @cache_file = File.expand_path('cache.json', @dir)
    if File.file?(@cache_file)
      @cache = JSON.parse(File.read(@cache_file))
    end
    @index = 0
  end

  #
  def download(photos)
    pageToken = nil
    while result = photos.mediaItems(pageToken: pageToken)
      result = JSON.parse(result)
      if items = result['mediaItems']
        items.each { |item|
          download_item(item)
        }
      end
      unless pageToken = result['nextPageToken']
        break
      end
    end
  end

  #
  def download_item(item)
    print(item['filename'])
    id = item['id']
    if file = @cache[id] and File.exist?(file)
      puts(' skip')
    else
      file = File.expand_path(item['filename'].gsub(/(\.\w+)$/, ".#{@cache.size}\\1"), @dir)
      OpenURI.open_uri(item['baseUrl']) { |input|
        File.open(file, 'wb') { |output|
          output.write(input.read)
        }
        @cache[id] = file
        File.open(@cache_file, 'w') { |fd| fd.write(JSON.pretty_generate(@cache)) }
        puts(' ok')
      }
    end
  end
end

#
auth = Auth.new([ 'https://www.googleapis.com/auth/photoslibrary.readonly' ])
if credentials = auth.auth
  photos = Photos.new(credentials)
  Downloader.new('photos').download(photos)
end
