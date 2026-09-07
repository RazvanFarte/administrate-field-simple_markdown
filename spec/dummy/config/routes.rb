# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :admin do
    resources :articles
    root to: 'articles#index'
  end

  get '/bench/edit', to: 'bench#edit'

  root to: redirect('/admin')
end
