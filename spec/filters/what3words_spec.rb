# encoding: utf-8
require 'spec_helper'
require "logstash/filters/what3words"

describe LogStash::Filters::What3Words do
  describe "Forward and reverse for index.home.raft" do
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
      insist { subject.get("[what3words][words]") } == "index.home.raft"
    end

    sample("message" => "51.521251, -0.203586") do
      insist { subject.get("[what3words][words]") } == "index.home.raft"
    end
  end
end
