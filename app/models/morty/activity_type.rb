module Morty
  class ActivityType < ApplicationRecord
    lookup_by :activity_type, cache: true

    has_many :activities
  end
end
