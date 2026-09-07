# frozen_string_literal: true

# Created at boot rather than through migrations: the dummy app has one table
# and no history worth keeping.
ActiveRecord::Schema.verbose = false
ActiveRecord::Base.connection.create_table :articles, if_not_exists: true do |t|
  t.string :title
  Article::MARKDOWN_ATTRIBUTES.each { |attribute| t.text attribute }
  t.timestamps
end
