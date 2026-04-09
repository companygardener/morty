module Morty
  class Rate
    include Comparable

    attr_reader :daily, :daily_leap, :monthly, :yearly

    def initialize(annual_rate)
      case annual_rate
      when self.class
        @rate = annual_rate.yearly
      else
        @rate = annual_rate.to_d
      end

      @daily      = @rate./(365).round(8)
      @daily_leap = @rate./(366).round(8)

      @monthly    = @rate./(12).round(8)
      @yearly     = @rate
    end

    def <=>(other)
      case other
      when Rate
        yearly <=> other.yearly
      else
        yearly <=> self.class.new(other).yearly
      end
    end

    def annual_percentage
      "%.3f" % (@yearly * 100)
    end

    def daily_for(date)
      date.leap? ? daily_leap : daily
    end

    def daily_percentage
      "%.8f" % (daily * 100)
    end

    def daily_percentage_leap
      "%.8f" % (daily_leap * 100)
    end

    def inspect
      "#<Morty::Rate: #{annual_percentage}% annually, #{daily_percentage}%/#{daily_percentage_leap}% daily>"
    end

    def to_d
      yearly
    end

    def to_s
      "%.2f" % @yearly
    end
  end
end
