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
class PhotosLocal
  #
  UNALBUMED = 'unalbumed'

  #
  def initialize
    @auth = Auth.new([ 'https://www.googleapis.com/auth/photoslibrary' ])
    if credentials = @auth.auth
      @photos = Photos.new(credentials)
      #Downloader.new('photos').download(photos)
      #puts(photos.albums)
      #puts(photos.create_album('unalbumed'))
    end
  end

  #
  def getAllAlbums
    unless @albums
      @albums = @photos.getAllAlbums
      @unalbumed = nil
      @albums.each { |album|
        if album.writeable? and album.title == UNALBUMED
          @unalbumed = album
        end
        album.items = @photos.searchAll(album.id)
        puts(album.to_s)
      }
      unless @unalbumed
        puts("album: create #{UNALBUMED}")
        @unalbumed = @photos.createAlbum(UNALBUMED)
      end
    end
    return @albums
  end

  #
  def getAllItems
    unless @allItems
      @allItems = @photos.getAllItems { |items| puts("items: #{items.size}") }
    end
    return @allItems
  end

  #
  def updateUnalbumed
    unalbumedIds = getUnalbumedIds
    currentIds = @unalbumed.items.collect { |item| item['id'] }
    ids = unalbumedIds - currentIds
    while !ids.empty?
      puts("unalbumed: +#{ids.size}")
      @photos.addItems(@unalbumed.id, ids.slice!(0, 50))
    end
    ids = currentIds - unalbumedIds
    while !ids.empty?
      puts("unalbumed: -#{ids.size}")
      @photos.removeItems(@unalbumed.id, ids.slice!(0, 50))
    end
  end

  #
  def getUnalbumedIds
    unalbumedIds = getAllItems.collect { |item| item['id'] }
    getAllAlbums.each { |album|
      if album != @unalbumed
        album.items.each { |item|
          unalbumedIds.delete(item['id'])
        }
      end
    }
    puts("unalbumeds: #{unalbumedIds.size}")
    return unalbumedIds
  end
 end

#Google::Apis.logger.level = Logger::DEBUG
photosLocal = PhotosLocal.new
photosLocal.updateUnalbumed
