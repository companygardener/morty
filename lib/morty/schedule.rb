module Morty
  class Schedule
    include Enumerable

    attr_reader :accountant, :events

    def initialize(accountant, list)
      @accountant = accountant


      @events = case list
                when nil      then []
                when Array    then list.map { |event| Event.new(event) }
                when Schedule then list.events
                end
    end

    def <<(events)
      @events += events.map { |event| Event.new(event) }
    end

    def between(start, finish)
      range = start.to_date .. finish.to_date

      events.select { |e| range.cover?(e.date) }
    end

    def each(&block)
      @events.each(&block)
    end

    def for(date)
      select { |e| e.date == date }
    end
  end
end
