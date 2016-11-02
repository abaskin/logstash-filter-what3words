# encoding: utf-8
require "logstash/filters/base"
require "logstash/namespace"
require "what3words"

# The what3words filter allows you to look up geodata using the What3Words
# API. The input is either a 3 word address as a string or geo corrdinates.
class LogStash::Filters::What3Words < LogStash::Filters::Base

  config_name "what3words"

  # Supply the What3Words API key.
  # Keys can be obtained here: https://map.what3words.com/register?dev=true
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       what3words {
  #         api_key => "zxse345s"
  #       }
  #     }
  config :api_key, :validate => :string, :required => true

  # Specify the language of the 3 word address and the returned data.
  # A supported 3 word address language as an ISO 639-1 2 letter code.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       what3words {
  #         lang => "en"
  #       }
  #     }
  config :lang, :validate => :string, :default => "en"

  # Specify the format of the returned data.
  # Can be one of json (the default), geojson or xml.
  # Json and geojson are returned as objects, xml as a string.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       what3words {
  #         format => "json"
  #       }
  #     }
  config :format, :validate => :string, :default => "json"

  # Specify the display type of the returned data.
  # Can be one of full (the default), terse (less output) or minimal (the bare minimum).
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       what3words {
  #         display => "full"
  #       }
  #     }
  config :display, :validate => :string, :default => "full"

  # The field containing a 3 word address as a string or geo corrdinates.
  # Geo corrdinates are a comma or space separated string of latitude and longitude
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       what3words {
  #         source => "message"
  #       }
  #     }
  config :source, :validate => :string, :default => "message"

  # The name of the field where the returned data will be stored.
  # Any current contents of that field will be overwritten.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       what3words {
  #         target => "what3words"
  #       }
  #     }
  config :target, :validate => :string, :default => "what3words"

  # Append values to the `tags` field when there has been an
  # error looking up geodata.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       what3words {
  #         tag_on_failure => [ "_what3wordsfailure" ]
  #       }
  #     }
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
  end # def unsymbolize
end # class LogStash::Filters::Example
