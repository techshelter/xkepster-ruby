# frozen_string_literal: true

require "spec_helper"

RSpec.describe Xkepster::Resources::Groups do
  let(:api_key) { "test_key" }
  let(:client) { Xkepster::Client.new(api_key: api_key, base_url: "https://api.xkepster.com") }
  let(:groups) { client.groups }
  let(:group_id) { "group-uuid" }

  describe "#create" do
    before do
      stub_request(:post, "https://api.xkepster.com/groups")
        .with(
          body: {
            data: {
              type: "groups",
              attributes: {
                name: "Test Group",
                description: "Test Description",
                auth_strategy: "both",
                allow_registration: true
              }
            }
          }.to_json,
          headers: {
            "X-Kepster-Key" => api_key,
            "Content-Type" => "application/vnd.api+json",
            "Accept" => "application/vnd.api+json"
          }
        )
        .to_return(
          status: 201,
          body: {
            data: {
              type: "groups",
              id: group_id,
              attributes: {
                name: "Test Group",
                description: "Test Description",
                auth_strategy: "both",
                allow_registration: true
              }
            }
          }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
    end

    it "creates a group with named parameters" do
      result = groups.create(
        name: "Test Group",
        description: "Test Description",
        auth_strategy: "both",
        allow_registration: true
      )

      expect(result["data"]["attributes"]["name"]).to eq("Test Group")
    end
  end

  describe "#update" do
    before do
      stub_request(:patch, "https://api.xkepster.com/groups/#{group_id}")
        .with(
          body: {
            data: {
              type: "groups",
              id: group_id,
              attributes: {
                name: "Updated Group",
                description: "Updated Description"
              }
            }
          }.to_json,
          headers: {
            "X-Kepster-Key" => api_key,
            "Content-Type" => "application/vnd.api+json",
            "Accept" => "application/vnd.api+json"
          }
        )
        .to_return(
          status: 200,
          body: {
            data: {
              type: "groups",
              id: group_id,
              attributes: {
                name: "Updated Group",
                description: "Updated Description",
                auth_strategy: "both",
                allow_registration: true
              }
            }
          }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
    end

    it "updates a group with named parameters" do
      result = groups.update(
        group_id,
        name: "Updated Group",
        description: "Updated Description"
      )

      expect(result["data"]["attributes"]["name"]).to eq("Updated Group")
      expect(result["data"]["attributes"]["description"]).to eq("Updated Description")
    end

    it "builds correct payload with only provided parameters" do
      groups.update(group_id, name: "Updated Group", description: "Updated Description")

      expect(WebMock).to have_requested(:patch, "https://api.xkepster.com/groups/#{group_id}")
        .with(
          body: {
            data: {
              type: "groups",
              id: group_id,
              attributes: {
                name: "Updated Group",
                description: "Updated Description"
              }
            }
          }.to_json
        )
    end
  end

  describe "#update with partial parameters" do
    before do
      stub_request(:patch, "https://api.xkepster.com/groups/#{group_id}")
        .with(
          body: {
            data: {
              type: "groups",
              id: group_id,
              attributes: {
                name: "Only Name Updated"
              }
            }
          }.to_json
        )
        .to_return(
          status: 200,
          body: {
            data: {
              type: "groups",
              id: group_id,
              attributes: {
                name: "Only Name Updated",
                description: "Original Description",
                auth_strategy: "both",
                allow_registration: true
              }
            }
          }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
    end

    it "updates only the specified parameters" do
      groups.update(group_id, name: "Only Name Updated")

      expect(WebMock).to have_requested(:patch, "https://api.xkepster.com/groups/#{group_id}")
        .with(
          body: {
            data: {
              type: "groups",
              id: group_id,
              attributes: {
                name: "Only Name Updated"
              }
            }
          }.to_json
        )
    end
  end

  describe "#retrieve" do
    context "with default fields" do
      before do
        stub_request(:get, "https://api.xkepster.com/groups/#{group_id}")
          .with(
            query: {
              fields: {
                groups: "name,description,auth_strategy,allow_registration"
              }
            },
            headers: {
              "X-Kepster-Key" => api_key,
              "Accept" => "application/vnd.api+json"
            }
          )
          .to_return(
            status: 200,
            body: {
              data: {
                type: "groups",
                id: group_id,
                attributes: {
                  name: "Test Group",
                  description: "Test Description",
                  auth_strategy: "both",
                  allow_registration: true
                }
              }
            }.to_json,
            headers: { "Content-Type" => "application/vnd.api+json" }
          )
      end

      it "retrieves a group with all attributes by default" do
        result = groups.retrieve(group_id)
        
        expect(result["data"]["attributes"]["name"]).to eq("Test Group")
        expect(result["data"]["attributes"]["description"]).to eq("Test Description")
        expect(result["data"]["attributes"]["auth_strategy"]).to eq("both")
        expect(result["data"]["attributes"]["allow_registration"]).to eq(true)
      end
    end

    context "with custom fields as array" do
      before do
        stub_request(:get, "https://api.xkepster.com/groups/#{group_id}")
          .with(
            query: {
              fields: {
                groups: "name,description"
              }
            }
          )
          .to_return(
            status: 200,
            body: {
              data: {
                type: "groups",
                id: group_id,
                attributes: {
                  name: "Test Group",
                  description: "Test Description"
                }
              }
            }.to_json,
            headers: { "Content-Type" => "application/vnd.api+json" }
          )
      end

      it "retrieves a group with specified fields only" do
        result = groups.retrieve(group_id, fields: %w[name description])
        
        expect(result["data"]["attributes"]["name"]).to eq("Test Group")
        expect(result["data"]["attributes"]["description"]).to eq("Test Description")
      end
    end

    context "with custom fields as string" do
      before do
        stub_request(:get, "https://api.xkepster.com/groups/#{group_id}")
          .with(
            query: {
              fields: {
                groups: "name"
              }
            }
          )
          .to_return(
            status: 200,
            body: {
              data: {
                type: "groups",
                id: group_id,
                attributes: {
                  name: "Test Group"
                }
              }
            }.to_json,
            headers: { "Content-Type" => "application/vnd.api+json" }
          )
      end

      it "retrieves a group with single field" do
        result = groups.retrieve(group_id, fields: "name")
        
        expect(result["data"]["attributes"]["name"]).to eq("Test Group")
      end
    end
  end

  describe "#list" do
    before do
      stub_request(:get, "https://api.xkepster.com/groups")
        .with(
          query: {
            fields: {
              groups: "name,description,auth_strategy,allow_registration"
            }
          },
          headers: {
            "X-Kepster-Key" => api_key,
            "Accept" => "application/vnd.api+json"
          }
        )
        .to_return(
          status: 200,
          body: {
            data: [
              {
                type: "groups",
                id: group_id,
                attributes: {
                  name: "Test Group",
                  description: "Test Description",
                  auth_strategy: "both",
                  allow_registration: true
                }
              }
            ]
          }.to_json,
          headers: { "Content-Type" => "application/vnd.api+json" }
        )
    end

    it "lists groups with all attributes by default" do
      result = groups.list
      
      expect(result["data"]).to be_an(Array)
      expect(result["data"].first["attributes"]["name"]).to eq("Test Group")
      expect(result["data"].first["attributes"]["description"]).to eq("Test Description")
    end
  end

  describe "#delete" do
    before do
      stub_request(:delete, "https://api.xkepster.com/groups/#{group_id}")
        .with(
          headers: {
            "X-Kepster-Key" => api_key,
            "Accept" => "application/vnd.api+json"
          }
        )
        .to_return(
          status: 204,
          body: ""
        )
    end

    it "deletes a group" do
      result = groups.delete(group_id)
      
      expect(WebMock).to have_requested(:delete, "https://api.xkepster.com/groups/#{group_id}")
    end
  end
end
