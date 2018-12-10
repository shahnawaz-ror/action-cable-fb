# frozen_string_literal: true

json.extract! notification, :id, :title, :description, :created_at, :updated_at
json.url notification_url(notification, format: :json)
