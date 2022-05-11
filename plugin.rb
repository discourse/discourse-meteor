# frozen_string_literal: true
# name: discourse-meteor
# about: Meteor's OAuth Plugin
# version: 0.1
# authors: Robin Ward
# transpile_js: true

require_dependency "auth/oauth2_authenticator.rb"

class ::OmniAuth::Strategies::Oauth2Meteor < ::OmniAuth::Strategies::OAuth2
  option :name, "oauth2_meteor"

  def callback_url
    full_host + script_name + callback_path
  end
end

class MeteorAuthenticator < ::Auth::OAuth2Authenticator
  def register_middleware(omniauth)
    omniauth.provider(
      :oauth2_meteor,
      name: "meteor",
      client_id: GlobalSetting.try(:meteor_client_id),
      client_secret: GlobalSetting.try(:meteor_client_secret),
      provider_ignores_state: true,
      client_options: {
        site: "https://accounts.meteor.com",
        authorize_url: "/oauth2/authorize",
        token_url: "/oauth2/token"
      }
    )
  end

  def after_authenticate(auth)
    result = Auth::Result.new
    token = Addressable::URI.escape(auth["credentials"]["token"])
    token.gsub!(/\+/, "%2B")

    user = JSON.parse(open("https://accounts.meteor.com/api/v1/identity", { "Authorization" => "Bearer #{token}" }).read)

    result.username = user["username"]
    if user["emails"].present?
      email = user["emails"].find { |e| e["primary"] }
      if email.present?
        result.email = email["address"]
        result.email_valid = email["verified"]
      end
    end

    current_info = ::PluginStore.get("meteor", "meteor_user_#{user["id"]}")
    if current_info
      result.user = User.where(id: current_info[:user_id]).first
    end

    if result.email && result.email_valid
      result.user ||= User.find_by_email(result.email)
    end

    result.extra_data = { meteor_user_id: user["id"] }
    result
  end

  def after_create_account(user, auth)
    ::PluginStore.set("meteor", "meteor_user_#{auth[:extra_data][:meteor_user_id]}", { user_id: user.id })
  end

  def enabled?
    true
  end
end

auth_provider(
  title: "with Meteor",
  authenticator: MeteorAuthenticator.new("meteor"),
  message: "Meteor"
)

register_css <<~CSS
  button.btn-social.meteor {
    background-color: #de4f4f;
  }
CSS
