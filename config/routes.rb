Rails.application.routes.draw do
  devise_for :users

  resources :dojos, only: [:index, :new, :create, :edit, :update, :destroy]

  get  '/taikais/:id/judging',                          to: 'judging#index',         as: :judging_index
  post '/taikais/:id/judging/:participant_id/update',   to: 'judging#update',        as: :judging_update
  get  '/taikais/:id/leaderboard',                      to: 'leader_board#index',    as: :leaderboard_index
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
