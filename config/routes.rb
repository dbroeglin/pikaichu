Rails.application.routes.draw do
  devise_for :users

  resources :dojos, only: [:index, :new, :create, :edit, :update, :destroy]
  resources :taikais, only: [:index, :new, :create, :edit, :update, :destroy] do
    resources :participating_dojos do
      resources :participants
    end
  end

  get '/taikais/:id/judging',                          to: 'judging#index',   as: :judging_index
  post '/taikais/:id/judging/:participant_id/update',  to: 'judging#update',  as: :judging_update

  get 'leader_board',                                  to: 'leader_board#index'

  root to: 'home#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
