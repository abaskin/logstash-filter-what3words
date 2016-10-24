# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "what3words"

class LogStash::Filters::What3Words < LogStash::Filters::Base

  config_name "what3words"

  config :api_key, :validate => :string, :required => true
  config :lang, :validate => :string, :default => "en"
  config :format, :validate => :string, :default => "full"
  config :display, :validate => :string, :default => "json"
  config :source, :validate => :string, :default => "message"
  config :target, :validate => :string, :default => "what3words"
  config :tag_on_failure, :validate => :array, :default => ["_what3wordsfailure"]

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

    m = forward_re.match(event.get(@source))
    if m
      begin
        result = what3words.forward m[2], :lang => @lang, :format => @format, :display => @display
      rescue Exception => e
        @logger.warn("What3Words threw exception", :exception => e.message, :backtrace => e.backtrace, :class => e.class.name)
        @tag_on_failure.each {|tag| event.tag(tag)}
        return
      end
    end

    m = reverse_re.match(event.get(@source))
    if m
      begin
        result = what3words.reverse [m[1],m[2]], :lang => @lang, :format => @format, :display => @display
      rescue Exception => e
        @logger.warn("What3Words threw exception", :exception => e.message, :backtrace => e.backtrace, :class => e.class.name)
        @tag_on_failure.each {|tag| event.tag(tag)}
        return
      end
    end

    if (result).nil?
      @logger.warn("Not a valid 3 word address", :address => event.get(@source))
      @tag_on_failure.each {|tag| event.tag(tag)}
    elsif results[:properties][:status].has_key?(:code)
      @logger.warn("What3Words returned an error code", :code => geojson[:properties][:status][:code], :error => geojson[:properties][:status][:message])
      @tag_on_failure.each {|tag| event.tag(tag)}
    else
      event.set(@target,result)
      filter_matched(event)
    end
  end # def filter
end # class LogStash::Filters::Example
