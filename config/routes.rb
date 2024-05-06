Rails.application.routes.draw do
  get 'reports/home' 
  get 'reports/range', as: 'range_report'
  post 'reports/execute_range', as: 'execute_range_report'
  get 'reports/mttm'
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "reports#home"
end
