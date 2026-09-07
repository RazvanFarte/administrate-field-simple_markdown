# frozen_string_literal: true

# 'rails' before 'administrate/engine': Administrate 0.x requires jquery-rails
# at load time, which reads Rails.env, so the Rails module has to exist first.
# Without this the gem cannot even be required outside a booted application.
require 'rails'
require 'rails/engine'
require 'administrate/engine'

module AdministrateFieldEasymde
  # Ships the bundled EasyMDE build to the host application.
  #
  # The assets are prebuilt into +app/assets/builds+ rather than assembled at
  # request time from Sprockets +//= require+ directives, because Administrate
  # 1.0 dropped its sprockets-rails dependency and hosts are free to run
  # Propshaft instead. A prebuilt file resolves under either pipeline.
  class Engine < ::Rails::Engine
    engine_name 'administrate_field_easymde'

    ASSETS = %w[
      administrate-field-easymde/application.js
      administrate-field-easymde/application.css
    ].freeze

    initializer 'administrate_field_easymde.assets.precompile' do |app|
      next unless app.config.respond_to?(:assets)

      app.config.assets.precompile += ASSETS
    end

    initializer 'administrate_field_easymde.administrate.register' do
      Engine.register(:javascript, 'administrate-field-easymde/application')
      Engine.register(:stylesheet, 'administrate-field-easymde/application')
    end

    # Administrate holds these in class variables, so registering the same path
    # twice renders two <script> tags and boots EasyMDE twice.
    def self.register(kind, path)
      reader = :"#{kind}s"
      return unless ::Administrate::Engine.respond_to?(reader)
      return if ::Administrate::Engine.public_send(reader).include?(path)

      ::Administrate::Engine.public_send(:"add_#{kind}", path)
    end
  end
end
