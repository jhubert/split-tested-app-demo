class GeneralController < ApplicationController
  # Action and Fragment Caching is supported automatically
  caches_action :index

  def index
  end
end
