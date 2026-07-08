# frozen_string_literal: true

RSpec.describe "Meteor OAuth2" do
  let(:access_token) { "meteor_access_token_448" }
  let(:client_id) { "abcdef11223344" }
  let(:client_secret) { "adddcccdddd99922" }
  let(:temp_code) { "meteor_temp_code_544254" }

  fab!(:user)

  before do
    GlobalSetting.stubs(:meteor_client_id).returns(client_id)
    GlobalSetting.stubs(:meteor_client_secret).returns(client_secret)

    stub_request(:post, "https://accounts.meteor.com/oauth2/token").to_return(
      status: 200,
      body: Rack::Utils.build_query(access_token: access_token, token_type: "bearer"),
      headers: {
        "Content-Type" => "application/x-www-form-urlencoded",
      },
    )

    stub_request(:get, "https://accounts.meteor.com/api/v1/identity").with(
      headers: {
        "Authorization" => "Bearer #{access_token}",
      },
    ).to_return(
      status: 200,
      body:
        JSON.dump(
          id: "meteor-user-id",
          username: "meteor-user",
          emails: [{ address: user.email, primary: true, verified: true }],
        ),
      headers: {
        "Content-Type" => "application/json",
      },
    )
  end

  it "rejects callbacks with missing or mismatched state before fetching the Meteor identity" do
    [nil, "mismatched-state"].each do |state|
      post "/auth/meteor"
      expect(response.status).to eq(302)
      expect(response.location).to start_with("https://accounts.meteor.com/oauth2/authorize")

      params = { code: temp_code }
      params[:state] = state if state

      post "/auth/meteor/callback", params: params

      expect(response.status).to eq(302)
      expect(response.location).to include("/auth/failure?message=csrf_detected")
      expect(session[:current_user_id]).to be_blank
    end

    expect(WebMock).not_to have_requested(:get, "https://accounts.meteor.com/api/v1/identity")
  end
end
