# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xkpester::Client do
  let(:api_key) { "test_key" }
  let(:client) { described_class.new(api_key: api_key, base_url: "https://api.xkepster.com") }

  describe "#initialize" do
    it "sets the api key from parameters" do
      expect(client.config.api_key).to eq(api_key)
    end

    it "sets default base_url" do
      expect(client.config.base_url).to eq("https://api.xkepster.com")
    end
  end

  describe "#users" do
    it "returns a Users resource" do
      expect(client.users).to be_a(Xkpester::Resources::Users)
    end
  end

  describe "#groups" do
    it "returns a Groups resource" do
      expect(client.groups).to be_a(Xkpester::Resources::Groups)
    end
  end

  describe "#sms_auth" do
    it "returns a SmsAuth resource" do
      expect(client.sms_auth).to be_a(Xkpester::Resources::SmsAuth)
    end
  end

  describe "#email_auth" do
    it "returns an EmailAuth resource" do
      expect(client.email_auth).to be_a(Xkpester::Resources::EmailAuth)
    end
  end

  describe "#sessions" do
    it "returns a Sessions resource" do
      expect(client.sessions).to be_a(Xkpester::Resources::Sessions)
    end
  end

  describe "#tokens" do
    it "returns a Tokens resource" do
      expect(client.tokens).to be_a(Xkpester::Resources::Tokens)
    end
  end

  describe "HTTP methods" do
    before do
      stub_request(:get, "https://api.xkepster.com/test")
        .to_return(status: 200, body: '{"data": []}', headers: { "Content-Type" => "application/vnd.api+json" })
    end

    it "makes GET requests with proper headers" do
      client.get("/test")

      expect(WebMock).to have_requested(:get, "https://api.xkepster.com/test")
        .with(headers: {
          "X-Kepster-Key" => api_key,
          "Content-Type" => "application/vnd.api+json",
          "Accept" => "application/vnd.api+json"
        })
    end
  end

  describe "error handling" do
    it "raises AuthenticationError when API key is missing" do
      client = described_class.new(api_key: nil)
      
      expect { client.users.list }.to raise_error(Xkpester::AuthenticationError, /API key is missing/)
    end
  end
end