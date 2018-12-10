# frozen_string_literal: true

class Student < ApplicationRecord
  belongs_to :user
end
