require 'googleauth'
require 'googleauth/stores/file_token_store'

#
class Auth
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'

  #
  def initialize(scope, 
                 client_secret: 'private/client_secret.json', 
                 token: 'private/token.yaml', 
                 user_id: 'default')
    @scope = scope
    @client_secret = client_secret
    @token = token
    @user_id = user_id
  end

  #
  def auth
    client_id = Google::Auth::ClientId.from_file(@client_secret)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: @token)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, @scope, token_store)
    unless credentials = authorizer.get_credentials(@user_id)
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts("Open #{url} in your brower and enter the resulting code:")
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: @user_id, 
                                                                   code: code, 
                                                                   base_url: OOB_URI)
    end
    return credentials
  end
end
