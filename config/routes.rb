# frozen_string_literal: true

 Rails.application.routes.draw do
  resources :tasks
  resources :products
  resources :notifications
   get 'home/index'
   devise_for :users
  resources :students
  root 'notifications#index'
  get '/notifications/status/:id' => 'notifications#status', :as => '/status'
  post '/notifications/change_status/:id' => 'notifications#change_status', :as => '/change_status'
  resources :charges
  get '/check_data' => 'notifications#check_data', :as => '/check_data'
  get '/stop_data' => 'notifications#stop_data', :as => '/stop_data'
end