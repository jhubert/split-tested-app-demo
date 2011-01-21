ABTestedApp::Application.routes.draw do
  get 'about' => "general#about"

  root :to => 'general#index'
end
