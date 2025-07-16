require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module WoocommerceMiddleware
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.0

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Internationalization configuration
    config.i18n.available_locales = [:en, :hu]
    config.i18n.default_locale = :hu
    config.time_zone = 'Budapest'

    config.active_record.encryption.primary_key = ENV['ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY']
    config.active_record.encryption.deterministic_key = ENV['ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY']
    config.active_record.encryption.key_derivation_salt = ENV['ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT']

    config.after_initialize do
      if Rails.application.credentials.active_record_encryption.present?
        ActiveRecord::Encryption.configure(
          primary_key: Rails.application.credentials.active_record_encryption[:primary_key],
          deterministic_key: Rails.application.credentials.active_record_encryption[:deterministic_key],
          key_derivation_salt: Rails.application.credentials.active_record_encryption[:key_derivation_salt]
        )
      end
    end
  end
end
