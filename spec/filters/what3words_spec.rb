# encoding: utf-8
require 'spec_helper'
require "logstash/filters/what3words"

describe LogStash::Filters::What3Words do
  describe "Forward index.home.raft" do
    let(:config) do <<-CONFIG
      filter {
        what3words {
          api_key => "3ZRSISHE"
        }
      }
    CONFIG
    end

    sample("message" => "index.home.raft") do
      expect(subject.get("[properties][status][status]")).to eq(200)
    end
  end
end
