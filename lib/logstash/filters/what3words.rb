# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "what3words"

class LogStash::Filters::What3Words < LogStash::Filters::Base

  config_name "what3words"

  config :api_key, :validate => :string, :required => true
  config :lang, :validate => :string, :default => "en"
  config :format, :validate => :string, :default => "json"
  config :display, :validate => :string, :default => "full"
  config :source, :validate => :string, :default => "message"
  config :target, :validate => :string, :default => "what3words"
  config :tag_on_failure, :validate => :array, :default => ["_what3wordsfailure"]

  public
  def register
    @forward_re = /^(http:\/\/w3w.co\/)?([a-z]+\.[a-z]+\.[a-z]+)$/
    @reverse_re = /^([\-\d]+\.\d+)[\s\,]+([\-\d]+\.\d+)$/
  end # def register

  public
  def filter(event)
    return unless event.include?(@source)

    what3words = What3Words::API.new(:key => @api_key)

    forw = @forward_re.match(event.get(@source))
    rev = @reverse_re.match(event.get(@source))

    begin
      result = what3words.forward forw[2], :lang => @lang, :format => @format, :display => @display if forw
      result = what3words.reverse [rev[1],rev[2]], :lang => @lang, :format => @format, :display => @display if rev
    rescue Exception => e
      @logger.warn("What3Words threw exception", :exception => e.message, :backtrace => e.backtrace, :class => e.class.name)
      @tag_on_failure.each {|tag| event.tag(tag)}
      return
    end

    if (result).nil?
      @logger.warn("Not a valid 3 word address", :address => event.get(@source))
      @tag_on_failure.each {|tag| event.tag(tag)}
    else
      event.set(@target,unsymbolize(result))
      filter_matched(event)
    end
  end # def filter

  private
  def unsymbolize(obj)
    return obj.inject({}){|memo,(k,v)| memo[k.to_s] =  unsymbolize(v); memo} if obj.is_a? Hash
    return obj.inject([]){|memo,v    | memo           << unsymbolize(v); memo} if obj.is_a? Array
    return obj
  end
end # class LogStash::Filters::Example
