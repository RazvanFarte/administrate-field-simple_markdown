# frozen_string_literal: true

require_relative 'application'

Rails.application.initialize!

require_relative '../db/schema'
require_relative '../db/seeds'
