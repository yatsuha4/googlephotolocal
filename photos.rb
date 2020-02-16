require 'google/apis/core/base_service'
require 'google/apis/core/json_representation'

#
class Photos < Google::Apis::Core::BaseService
  #
  def initialize(credentials)
    super('https://photoslibrary.googleapis.com/', 'v1/')
    self.authorization = credentials
  end

  #
  def mediaItems(pageSize: 100, pageToken: nil, options: nil, &block)
    command = make_simple_command(:get, 'mediaItems', options)
    #command.response_representation = MediaItems::Representation
    #command.response_class = MediaItems
    command.query['pageSize'] = pageSize
    command.query['pageToken'] = pageToken if pageToken
    return execute_or_queue_command(command, &block)
  end
end
