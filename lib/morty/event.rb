module Morty
  class Event
    attr_reader :info

    def initialize(event)
      case event
      when Activity then @info = event.to_event
      when Event    then @info = event.info
      when Hash     then @info = { amount: event[:amount], date: event[:date], type: event[:type] }
      else
        raise Error, "Event.new takes an Activity, Event, or Hash(:amount, :date, :type)"
      end
    end

    def amount
      @info[:amount]
    end

    def date
      @info[:date]
    end

    def type
      @info[:type]
    end
  end
end
