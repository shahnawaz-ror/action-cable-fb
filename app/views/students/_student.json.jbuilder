# frozen_string_literal: true

json.extract! student, :id, :name, :roll_number, :created_at, :updated_at
json.url student_url(student, format: :json)
