module Morty
  class Diff
    def initialize(original, adjusted)
      @original = original.activities
      @adjusted = adjusted.activities
    end

    def entries
      original_sums = Sum.new(@original)
      adjusted_sums = Sum.new(@adjusted.list - additional.list)

      diff = adjusted_sums - original_sums

      diff.map { |type, amount| Entry.new(entry_type: type, amount: amount) }
    end

    def additional
      @additional ||= @adjusted.reject { |a| a.type?(:interest) || original?(a) }
    end

    def original?(activity)
      @original.include?(activity)
    end

    class Sum
      def initialize(activities)
        @entries = activities.flat_map(&:entries)
      end

      def calculate
        return @hash if @hash

        hash = @entries.each_with_object(Hash.new(0.to_d)) do |entry, sums|
          sums[entry.type] += entry.amount
        end

        @hash = reduce(hash)
      end

      # @param other Sum
      def -(other)
        left = calculate
        right = other.calculate

        types = left.keys + right.keys

        result = types.uniq.each_with_object(Hash.new(0.to_d)) do |type, sums|
          sums[type] = left[type] - right[type]
        end

        reduce(result)
      end

      def reduce(input)
        input.each_with_object(Hash.new(0.to_d)) do |(type, amount), sums|
          inverse = type.inverse

          next if sums.key?(type) || sums.key?(inverse)

          amount -= input[inverse] if input.key?(inverse)

          case
          when amount  > 0 then sums[type]    += amount
          when amount  < 0 then sums[inverse] += amount.abs
          when amount == 0 then next
          end
        end
      end
    end
  end
end
