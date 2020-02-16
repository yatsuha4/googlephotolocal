require 'google/apis/core/base_service'
require 'google/apis/core/json_representation'

require_relative 'album'

#
class Photos < Google::Apis::Core::BaseService
  #
  class Value
    #
    def initialize
      @value = nil
    end

    #
    attr_accessor :value

    #
    def [](key)
      return @value[key]
    end

    #
    class Representation
      #
      def initialize(value)
        @value = value
      end

      #
      def from_json(json, *args)
        @value.value = JSON.parse(json)
      end

      #
      def to_json(*args)
        return JSON.generate(@value)
      end
    end
  end

  #
  def initialize(credentials)
    super('https://photoslibrary.googleapis.com/', 'v1/')
    self.authorization = credentials
  end

  #
  def getAllAlbums(&proc)
    albums = Array.new
    eachAll { |pageToken|
      if result = getAlbums(pageToken: pageToken)
        result['albums']&.each { |album|
          albums.push(Album.new(album))
        }
        proc&.call(albums)
      end
      result
    }
    return albums
  end

  #
  def searchAll(albumId)
    items = Array.new
    eachAll { |pageToken|
      if result = search(albumId, pageToken: pageToken)
        if result['mediaItems']
          items.concat(result['mediaItems'])
        end
      end
      result
    }
    return items
  end

  #
  def getAllItems(&proc)
    items = Array.new
    eachAll { |pageToken|
      if result = getItems(pageToken: pageToken)
        if result['mediaItems']
          items.concat(result['mediaItems'])
          proc&.call(items)
        end
      end
      result
    }
    return items
  end

  #
  def eachAll(&proc)
    pageToken = nil
    while result = proc.call(pageToken)
      unless pageToken = result['nextPageToken']
        break
      end
    end
  end

  #
  def getItems(pageSize: 100, pageToken: nil, options: nil, &block)
    command = make_simple_command(:get, 'mediaItems', options)
    command.query['pageSize'] = pageSize
    command.query['pageToken'] = pageToken if pageToken
    command.response_representation = Value::Representation
    command.response_class = Value
    return execute_or_queue_command(command, &block)
  end

  #
  def getAlbums(pageToken: nil, options: nil, &block)
    command = make_simple_command(:get, 'albums', options)
    command.response_representation = Value::Representation
    command.response_class = Value
    command.query['pageToken'] = pageToken if pageToken
    return execute_or_queue_command(command, &block)
  end

  #
  def search(albumId, pageSize: 100, pageToken: nil, options: nil, &block)
    command = make_simple_command(:post, 'mediaItems:search', options)
    command.request_representation = Value::Representation
    command.request_object = {
      'pageSize' => pageSize.to_s, 
      'albumId' => albumId
    }
    command.request_object['pageToken'] = pageToken if pageToken
    command.response_representation = Value::Representation
    command.response_class = Value
    return execute_or_queue_command(command, &block)
  end

  #
  def createAlbum(title, options: nil)
    command = make_simple_command(:post, 'albums', options)
    command.request_representation = Value::Representation
    command.request_object = { 'album' => { 'title' => title } }
    result = execute_or_queue_command(command)
    return result ? Album.new(result) : nil
  end

  #
  def addItems(albumId, itemIds, options: nil)
    command = make_simple_command(:post, "albums/#{albumId}:batchAddMediaItems", options)
    command.request_representation = Value::Representation
    command.request_object = { 'mediaItemIds' => itemIds }
    return execute_or_queue_command(command)
  end

  #
  def removeItems(albumId, itemIds, options: nil)
    command = make_simple_command(:post, "albums/#{albumId}:batchRemoveMediaItems", options)
    command.request_representation = Value::Representation
    command.request_object = { 'mediaItemIds' => itemIds }
    return execute_or_queue_command(command)
  end
end
