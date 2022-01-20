# rubocop:disable Layout/LineLength

Rails.application.routes.draw do
  devise_for :users

  resources :dojos, only: [:index, :new, :create, :edit, :update, :destroy]

  get  '/taikais/:id/marking',                          to: 'marking#show',                as: :show_marking
  post '/taikais/:id/marking/:participant_id/update',   to: 'marking#update',              as: :update_marking
  patch '/taikais/:id/marking/:participant_id/result/:result_id',
        to: 'marking#rotate',
        as: :rotate_marking
  patch '/taikais/:id/marking/:participant_id/finalize',
        to: 'marking#finalize',
        as: :finalize_round_marking
  get  '/taikais/:id/draw',                             to: 'taikais#draw',          as: :draw_taikai
  get  '/taikais/:id/leaderboard',                      to: 'leaderboard#show',      as: :show_taikai_leaderboard
  get  '/taikais/:id/leaderboard/public',               to: 'leaderboard#public',    as: :show_taikai_leaderboard_public
  get  '/taikais/:id/export.xlsx',                      to: 'taikais#export',        as: :taikai_export

  get '/taikais/:taikai_id/participating_dojos/(:participating_dojo_id)/available_users', to: 'search#dojos',
                                                                                          as: :taikai_participating_dojo_available_dojos
  get '/taikais/:taikai_id/staffs/(:staff_id)/available_users', to: 'search#users',
                                                                as: :taikai_staff_available_users

  get '/kyudojins/available', to: 'search#kyudojins',
                              as: :search_kyudojins

  resources :taikais, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    resources :participating_dojos do
      resources :participants do
        collection do
          post 'import'
        end
      end
      resources :teams do
        resources :participants do
          member do
            patch 'reorder'
          end
        end
      end
    end
    resources :staffs
  end

  root to: 'home#index'
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
