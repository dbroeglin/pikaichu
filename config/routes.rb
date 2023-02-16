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

  get '/taikais/:taikai_id/participating_dojos/(:participating_dojo_id)/available_users', to: 'search#dojos',
                                                                                          as: :taikai_participating_dojo_available_dojos
  get '/taikais/:taikai_id/staffs/(:staff_id)/available_users', to: 'search#users',
                                                                as: :taikai_staff_available_users

  get '/kyudojins/available', to: 'search#kyudojins',
                              as: :search_kyudojins

  resources :taikais, only: [:index, :show, :new, :create, :edit, :update, :destroy] do
    member do
      get   'export.xlsx',                      to: 'taikais#export', as: :taikai_export # TODO: refactor
      post  'generate'
      get   'leaderboard',                      to: 'leaderboard#show'
      get   'leaderboard/2in1',                 to: 'leaderboard#show_2in1'
      get   'leaderboard/public',               to: 'leaderboard#public'
      post  'transition_to'
    end
    resources :tie_break, only: [:index, :update]
    resources :rectification, only: [:index, :edit, :update]
    resources :matches do
      member do
        get 'marking', to: 'marking#show_match'
        patch 'select_winner'
      end
    end
    resources :participating_dojos do
      member do
        get 'draw'

        get 'teaming/edit'
        post 'teaming/create_team'
        post 'teaming/form_randomly'
        delete 'teaming/clear'
        patch 'teaming/move'
      end
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
