# frozen_string_literal: true

class NotificationsController < ApplicationController
  before_action :set_notification, only: %i[show edit update destroy]
  require 'rufus-scheduler'
  @@job = nil
  @@scheduler = nil

  include ActionView::Helpers::DateHelper

  # GET /notifications
  # GET /notifications.json
  def index
    @notifications = Notification.all
  end

  # GET /notifications/1
  # GET /notifications/1.json
  def show
    @notification.update(status: 1)
  end

  # GET /notifications/new
  def new
    @notification = Notification.new
  end

  # GET /notifications/1/edit
  def edit; end

  # POST /notifications
  # POST /notifications.json
  def create
    @notification = Notification.new(notification_params)
    respond_to do |format|
      @notification.status = 0
      if @notification.save
        format.html { redirect_to notifications_path, notice: 'Notification was successfully created.' }
        format.json { render :show, status: :created, location: @notification }
        
        ActionCable.server.broadcast 'notifications_channel', value: @notification, time_ago: time_ago_in_words(@notification.created_at), count: Notification.all.count, url: notification_path(@notification), unread_notification: Notification.where(status: 0).count
      else
        format.html { render :new }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end
  def check_data
    @@scheduler = Rufus::Scheduler.new
    @@job = @@scheduler.every '3s' do
      puts 'Hello... Rufus'
    end
    redirect_to root_path
  end

  def stop_data
    sleep 3
    debugger
    @@scheduler.stop if @@scheduler.running_jobs.present?
    redirect_to root_path
  end

  # PATCH/PUT /notifications/1
  # PATCH/PUT /notifications/1.json
  def update
    respond_to do |format|
      if @notification.update(notification_params)
        format.html { redirect_to @notification, notice: 'Notification was successfully updated.' }
        format.json { render :show, status: :ok, location: @notification }
      else
        format.html { render :edit }
        format.json { render json: @notification.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /notifications/1
  # DELETE /notifications/1.json
  def destroy
    @notification.destroy
    respond_to do |format|
      format.html { redirect_to notifications_url, notice: 'Notification was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def status
    notification = Notification.find_by_id(params['id'])
    data = notification.status ? 'shown' : 'not shown'
    render json: { status: data }
  end

  def change_status
    notification = Notification.find_by_id(params['id'])
    notification.status ? notification.update(status: 0) : notification.update(status: 1)
    render json: { status: 'changed', id: notification.id }
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_notification
    @notification = Notification.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def notification_params
    params.require(:notification).permit(:title, :description)
  end
end
