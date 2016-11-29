# encoding: utf-8
require "logstash/inputs/base"
require "logstash/namespace"
require "stud/interval"
require "socket" # for Socket.gethostname
require "net/http" # for calling web service url

# Generate a repeating message.
#
# This plugin is intented only as an example.

class LogStash::Inputs::Liferaystatus < LogStash::Inputs::Base
  config_name "liferaystatus"

  # If undefined, Logstash will complain, even if codec is unused.
  default :codec, "plain"

  # The message string to use in the event.
  config :message, :validate => :string, :default => "Hello World!"

  # Set how frequently messages should be sent.
  #
  # The default, `1`, means send a message every second.
  config :interval, :validate => :number, :default => 1

  public
  def register
    @host = Socket.gethostname
  end # def register

  def run(queue)
    url = 'http://localhost:8080/api/jsonws/liferay-status-portlet.liferaystatus/get-used-memory'   
    # we can abort the loop if stop? becomes true
    while !stop?
      response = Net::HTTP.get_response(URI.parse(url))
      
      event = LogStash::Event.new("memoryUsage" => response.body)
      
      decorate(event)
      queue << event
      # because the sleep interval can be big, when shutdown happens
      # we want to be able to abort the sleep
      # Stud.stoppable_sleep will frequently evaluate the given block
      # and abort the sleep(@interval) if the return value is true
      Stud.stoppable_sleep(@interval) { stop? }
    end # loop
  end # def run

  def stop
    # nothing to do in this case so it is not necessary to define stop
    # examples of common "stop" tasks:
    #  * close sockets (unblocking blocking reads/accepts)
    #  * cleanup temporary files
    #  * terminate spawned threads
  end
end # class LogStash::Inputs::Liferaystatus
