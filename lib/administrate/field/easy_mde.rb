# frozen_string_literal: true

require 'administrate/field/simple_markdown'

module Administrate
  module Field
    # Name that matches the gem, for dashboards that would rather write
    # Field::EasyMDE than Field::SimpleMarkdown. The two are the same field.
    class EasyMDE < SimpleMarkdown
      # Administrate builds the partial path from the field type. Reporting the
      # parent's type makes this class render with the SimpleMarkdown partials
      # instead of needing copies of its own, and it works on Administrate 0.x,
      # which looks the path up directly, as well as 1.0, which walks the
      # ancestry.
      def self.field_type
        superclass.field_type
      end
    end
  end
end
