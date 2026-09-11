# frozen_string_literal: true

RSpec.describe "MeteorAuthenticator" do
  subject(:authenticator) { Discourse.authenticators.find { it.name == "meteor" } }

  before do
    GlobalSetting.stubs(:meteor_client_id).returns("client_id")
    GlobalSetting.stubs(:meteor_client_secret).returns("client_secret")
  end

  it "enables login with configured global credentials" do
    expect(authenticator.enabled?).to eq(true)
  end

  %i[meteor_client_id meteor_client_secret].each do |setting|
    it "disables login without #{setting}" do
      GlobalSetting.stubs(setting).returns("")

      expect(authenticator.enabled?).to eq(false)
    end
  end
end
