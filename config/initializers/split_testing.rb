# Load the additional view folders so that they can be used on the fly
ActionController::Base.class_eval do

  SPLIT_TESTS = YAML.load_file("#{RAILS_ROOT}/config/split_tests.yml")

  def self.custom_view_path(name)
    name == "views" ? "app/views" : "test/split/#{name}/views"
  end

  def self.random_test_key
    split_test_map.sample
  end

  # preprocess some pathsets on boot
  # doing pathset generation during a request is very costly
  @@preprocessed_pathsets = begin
    SPLIT_TESTS.keys.reject { |k| k == 'BASELINE' }.inject({}) do |pathsets, slug|
      path = ActionController::Base.custom_view_path(slug)
      pathsets[path] = ActionView::Base.process_view_paths(path).first
      pathsets
    end
  end

  @@split_test_map = begin
    tm = {} # test map
    SPLIT_TESTS.each { |k, v| tm[k] = v['size'].to_i }
    tm.keys.zip(tm.values).collect { |v,d| (0...d).collect { v }}.flatten
  end

  cattr_accessor :preprocessed_pathsets, :split_test_map
end

# Add the split test language files to the load path
I18n.load_path += Dir[Rails.root.join('test', 'split', '*', 'locale.{rb,yml}')]

# Overwrite the translate method so that it tries the bucket translation first
# TODO: There HAS to be a better way to write this
module ActionView
  module Helpers
    module TranslationHelper
      def fallback_translate(key, options = {})
        translation = I18n.translate(scope_key_by_partial(key), options.merge!(:raise => true))
        if html_safe_translation_key?(key) && translation.respond_to?(:html_safe)
          translation.html_safe
        else
          translation
        end
      rescue I18n::MissingTranslationData => e
        keys = I18n.normalize_keys(e.locale, e.key, e.options[:scope])
        content_tag('span', keys.join(', '), :class => 'translation_missing')
      end

      def translate(key, options = {})
        original_options = options.clone
        options[:scope] = (options[:scope] ? "#{@split_test_key}.#{options[:scope]}" : @split_test_key) if @split_test_key
        translation = I18n.translate(scope_key_by_partial(key), options.merge!(:raise => true))
        if html_safe_translation_key?(key) && translation.respond_to?(:html_safe)
          translation.html_safe
        else
          translation
        end
      rescue I18n::MissingTranslationData => e
        fallback_translate(e.key, original_options)
      end
      alias t translate
    end
  end
end