Rails.application.routes.draw do
  get 'aha/explorer', as: 'aha_explorer'
  get 'aha/initiative_explorer', as: 'execute_aha_initiative_explorer'

  get 'reports/range', as: 'range_report'

  get 'reports/security', as: 'security_report'

  post 'reports/execute_security_export', as: 'execute_security_export'


  resources :reports, only: [] do
    collection do
      get :repos
      get :mttm
      get :home
    end
  end

  post 'reports/execute_range', as: 'execute_range_report'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "reports#home"
end
