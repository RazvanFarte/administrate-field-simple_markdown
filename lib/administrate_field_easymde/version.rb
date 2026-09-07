# frozen_string_literal: true

# Namespaced separately from Administrate::Field::SimpleMarkdown so that the
# gemspec can require this file on its own without defining the field class
# (and thereby fixing its superclass before Administrate is loaded).
module AdministrateFieldEasymde
  VERSION = '1.0.0'
end
