Rails.application.routes.draw do
  devise_for :users, controllers: {
    :registrations => 'users/registrations',
    :sessions => 'users/sessions',
    :omniauth_callbacks => 'users/omniauth_callbacks'
  }


  root 'items#index'
  get 'edit' => 'users#edit'
  # ルーティングは追って検討する


  resources :users, only: [:show, :new, :edit, :update] do
    collection do
      get 'signup/:url',action: 'new'
      get 'mypage/:url',action: 'edit'
    end
  end

  resources :items, only: [:index, :show, :new, :create] do
    collection do
      get 'trade/:url', action:'show'
    end

    resources :categories, only: [:search]
  end
  resources :cards, only: [:new, :show]
end
