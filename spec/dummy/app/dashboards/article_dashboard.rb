# frozen_string_literal: true

require 'administrate/base_dashboard'

class ArticleDashboard < Administrate::BaseDashboard
  MARKDOWN_FIELD = Field::SimpleMarkdown.with_options(
    easymde_options: {
      placeholder: 'Type Markdown here...',
      toolbar: [
        'bold', 'italic', '|',
        'heading-1', 'heading-2', 'heading-3',
        # The reason this fork exists: EasyMDE ships toggleHeading4/5/6 but
        # does not put them in the default toolbar.
        { name: 'heading-4', action: 'EasyMDE.toggleHeading4', text: 'H4', title: 'Heading 4' },
        { name: 'heading-5', action: 'EasyMDE.toggleHeading5', text: 'H5', title: 'Heading 5' },
        { name: 'heading-6', action: 'EasyMDE.toggleHeading6', text: 'H6', title: 'Heading 6' },
        '|', 'unordered-list', 'ordered-list', 'link', 'preview'
      ]
    }
  )

  ATTRIBUTE_TYPES = {
    id: Field::Number,
    title: Field::String,
    created_at: Field::DateTime
  }.merge(Article::MARKDOWN_ATTRIBUTES.to_h { |attribute| [attribute, MARKDOWN_FIELD] }).freeze

  # Administrate reads these constants from the instance, so the sweep has to
  # happen when the class is loaded rather than in an override.
  COLLECTION_ATTRIBUTES = (%i[id title] + Article.markdown_attributes).freeze
  SHOW_PAGE_ATTRIBUTES = (%i[id title created_at] + Article.markdown_attributes).freeze
  FORM_ATTRIBUTES = (%i[title] + Article.markdown_attributes).freeze
end
