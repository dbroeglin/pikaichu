Rails.application.routes.draw do
  devise_for :users

  resources :dojos, only: [:index, :new, :create, :edit, :update, :destroy]

  get  '/taikais/:id/marking',                          to: 'marking#show',          as: :show_marking
  post '/taikais/:id/marking/:participant_id/update',   to: 'marking#update',        as: :update_marking
  get  '/taikais/:id/leaderboard',                      to: 'leaderboard#show',     as: :show_leaderboard
  get  '/taikais/:id/export.xlsx',                      to: 'taikais#export',        as: :taikai_export

  get '/taikais/:taikai_id/participating_dojos/(:participating_dojo_id)/available_users', to: 'search#dojos',
      as: :taikai_participating_dojo_available_dojos
  get '/taikais/:taikai_id/staffs/(:staff_id)/available_users', to: 'search#users',
      as: :taikai_staff_available_users

  resources :taikais, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    resources :participating_dojos do
      resources :participants
      resources :teams do
        resources :participants
      end
    end
    resources :staffs
  end



  root to: 'home#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
