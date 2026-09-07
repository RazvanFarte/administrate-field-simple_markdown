# frozen_string_literal: true

class Article < ActiveRecord::Base
  # Enough Markdown columns for the browser benchmark to sweep how many
  # editors a single form page can carry.
  MAX_MARKDOWN_ATTRIBUTES = 20
  MARKDOWN_ATTRIBUTES = (1..MAX_MARKDOWN_ATTRIBUTES).map { |i| :"body_#{i}" }.freeze

  def self.markdown_attributes
    MARKDOWN_ATTRIBUTES.first(Rails.configuration.x.editor_fields)
  end
end
