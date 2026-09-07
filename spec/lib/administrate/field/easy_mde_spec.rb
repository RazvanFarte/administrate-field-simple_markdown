# frozen_string_literal: true

require 'spec_helper'
require 'administrate/field/easy_mde'

RSpec.describe Administrate::Field::EasyMDE do
  it 'behaves like the SimpleMarkdown field it is named after' do
    field = described_class.new(:body, '**hi**', :show)

    expect(field.to_html).to eq "<p><strong>hi</strong></p>\n"
  end

  it 'renders with the SimpleMarkdown partials rather than duplicating them' do
    expect(described_class.field_type).to eq 'simple_markdown'
  end
end
