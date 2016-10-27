# encoding: utf-8
require 'spec_helper'
require "logstash/filters/what3words"

describe LogStash::Filters::What3Words do
  describe "Lookup index.home.raft" do
    let(:config) do <<-CONFIG
      filter {
        what3words {
          api_key => "3ZRSISHE"
          # display => "full"
          # format => "json"
          # lang => "en"
        }
      }
    CONFIG
    end

    sample("message" => "index.home.raft") do
      expect(subject.get("[what3words][words]")).to eq("index.home.raft")
    end

    sample("message" => "51.521251, -0.203586") do
      expect(subject.get("[what3words][[words]")).to eq("index.home.raft")
    end
  end
end
