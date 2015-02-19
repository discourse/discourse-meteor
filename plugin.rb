# name: discourse-meteor
# about: Meteor's OAuth Plugin
# version: 0.1
# authors: Robin Ward

require_dependency 'auth/oauth2_authenticator.rb'

class MeteorAuthenticator < ::Auth::OAuth2Authenticator
  def register_middleware(omniauth)
    omniauth.provider :oauth2,
                      :name => 'meteor',
                      :client_id => GlobalSetting.meteor_client_id,
                      :client_secret => GlobalSetting.meteor_client_secret,
                      :provider_ignores_state => true,
                      :client_options => {
                        :site => 'https://www.meteor.com',
                        :authorize_url => '/oauth2/authorize',
                        :token_url => '/oauth2/token'
                      }
  end
end

auth_provider title: "with Meteor",
              authenticator: MeteorAuthenticator.new('meteor'),
              message: "Meteor"

register_css <<CSS

  button.btn-social.meteor {
    background-color: #de4f4f;
  }

CSS
