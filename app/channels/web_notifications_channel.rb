# frozen_string_literal: true

class WebNotificationsChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'web_notifications_channel'
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
