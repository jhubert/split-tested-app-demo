ABTestedApp::Application.routes.draw do
  get 'about' => "general#about", :as => :about

  root :to => 'general#index'
end
