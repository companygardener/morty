module Morty
  # A wrapper class for the object for which we are accounting
  class Source
    attr_reader :object

    delegate_missing_to :@object

    def initialize(object)
      raise Error, "source must define an id method" unless object.respond_to?(:id)

      @object = object
    end

    # has_many light
    def activities
      Activity.where(source_id: object.id)
    end
  end
end
