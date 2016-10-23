# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "what3words"

class LogStash::Filters::What3Words < LogStash::Filters::Base

  config_name "what3words"

  config :api_key, :validate => :password, :required => true
  config :lang, :validate => :string, :default => "en"
  config :format, :validate => :string, :default => "full"
  config :display, :validate => :string, :default => "json"
  config :source, :validate => :string, :default => "message"
  config :target, :validate => :string, :default => "what3words"

  public
  def register
    # Add instance variables
  end # def register

  public
  def filter(event)

    return unless event.include?(@source)

    forward_re = /^(http:\/\/w3w.co\/)?([a-z]+\.[a-z]+\.[a-z]+)$/
    reverse_re = /^(\d+\.\d+)\s+(\d+\.\d+)$/

    what3words = What3Words::API.new(:key => @api_key)

    m = forward_re.match(event.get(@fsource))
    if m
      result = what3words.forward m[2], :lang => @lang, :format => @format, :display => @display
    end

    m = reverse_re.match(event.get(@fsource))
    if m
      result = what3words.reverse [m[1],m[2]], :lang => @lang, :format => @format, :display => @display
    end

    unless (result).nil?
      event.set(@target,result)
      filter_matched(event)
    end
  end # def filter
end # class LogStash::Filters::Example
