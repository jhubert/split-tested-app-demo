class GeneralController < ApplicationController
  # Uses the custom_cache_path from ApplicationController
  # to make sure the right split test is cached
  caches_action :index, :cache_path => :custom_cache_path.to_proc

  def index
  end
end
