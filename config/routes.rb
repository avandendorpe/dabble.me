require 'sidekiq/web'

Rails.application.routes.draw do

  #constraints(:host => /localhost/) do
    mount Sidekiq::Web => '/sidekiq'
  #end

  devise_for :users, :controllers => { registrations: 'registrations' }

  get   '/entries/import/ohlife' => 'import#import_ohlife', :as => "import_ohlife"
  match '/entries/import/ohlife/process' => 'import#process_ohlife', via: [:put], :as => "import_ohlife_process"

  get '/entries/random' => 'entries#random', :as => "random_entry"

  resources :entries

  get   '/export' => 'entries#export', :as => "export_entries"

  root 'welcome#index'

  get '/privacy' => 'welcome#privacy'
  
  post '/email_processor' => 'griddler/emails#create'

end
