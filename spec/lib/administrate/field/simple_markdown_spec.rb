# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Administrate::Field::SimpleMarkdown do
  subject(:field) { described_class.new(:simple_markdown, data, :show, options.dup) }

  let(:md) { '**foo** is the new _bar_' }
  let(:text) { 'foo is the new bar' }
  let(:html) { '<p><strong>foo</strong> is the new <em>bar</em></p>' }
  let(:options) { {} }

  describe '#data' do
    let(:output) { field.data }

    context 'with nil' do
      let(:data) { nil }

      it 'returns an empty string' do
        expect(output).to eq ''
      end
    end

    context 'with data' do
      let(:data) { text }

      it 'returns the data' do
        expect(output).to eq text
      end
    end
  end

  describe '#easymde_options' do
    subject(:output) { JSON.parse(field.easymde_options) }

    let(:data) { text }

    context 'without configuration' do
      it 'keeps EasyMDE from downloading Font Awesome' do
        expect(output).to include('autoDownloadFontAwesome' => false)
      end

      it 'keeps EasyMDE from downloading a spell-check dictionary' do
        expect(output).to include('spellChecker' => false)
      end

      it 'claims the toolbar button classes so the bundled icons apply' do
        expect(output)
          .to include('toolbarButtonClassPrefix' => described_class::TOOLBAR_BUTTON_CLASS_PREFIX)
      end
    end

    context 'with valid options' do
      let(:options) do
        {
          easymde_options: {
            placeholder: 'Type here...',
            hide_icons: %w[foo bar]
          }
        }
      end

      it 'camelizes the keys EasyMDE expects in camelCase' do
        expect(output).to include(
          'placeholder' => 'Type here...',
          'hideIcons' => %w[foo bar]
        )
      end
    end

    context 'when a default is overridden' do
      let(:options) { { easymde_options: { spell_checker: true } } }

      it 'prefers the dashboard value' do
        expect(output).to include('spellChecker' => true)
      end
    end

    context 'when Font Awesome is asked for explicitly' do
      let(:options) { { easymde_options: { auto_download_font_awesome: true } } }

      it 'leaves the toolbar button classes to EasyMDE' do
        expect(output).not_to have_key('toolbarButtonClassPrefix')
      end
    end
  end

  describe '#input_options' do
    let(:data) { text }

    it 'carries the serialized EasyMDE options in a data attribute' do
      expect(field.input_options.dig(:data, :easymde_options)).to eq field.easymde_options
    end

    context 'with dashboard-supplied input options' do
      let(:options) { { input_options: { class: 'wide', data: { foo: 'bar' } } } }

      it 'keeps them' do
        expect(field.input_options).to include(class: 'wide')
        expect(field.input_options[:data]).to include(foo: 'bar')
      end
    end
  end

  describe '#to_s' do
    let(:output) { field.to_s }

    context 'with nil' do
      let(:data) { nil }

      it 'returns an empty string' do
        expect(output).to eq ''
      end
    end

    context 'with a string' do
      let(:data) { text }

      it 'returns the same string' do
        expect(output).to eq "#{text}\n"
      end
    end

    context 'with Markdown' do
      let(:data) { md }

      it 'strips out the formatting' do
        expect(output).to eq "#{text}\n"
      end
    end
  end

  describe '#to_html' do
    let(:output) { field.to_html }

    context 'with nil' do
      let(:data) { nil }

      it 'returns an empty string' do
        expect(output).to eq ''
      end
    end

    context 'with a string' do
      let(:data) { text }

      it 'wraps it in a paragraph' do
        expect(output).to eq "<p>#{text}</p>\n"
      end
    end

    context 'with Markdown' do
      let(:data) { md }

      it 'converts it to HTML' do
        expect(output).to eq "#{html}\n"
      end
    end
  end

  describe 'rendering the same field twice' do
    let(:data) { md }

    it 'does not reuse the HTML renderer for plain text' do
      field.to_html

      expect(field.to_s).to eq "#{text}\n"
    end

    it 'does not reuse the plain text renderer for HTML' do
      field.to_s

      expect(field.to_html).to eq "#{html}\n"
    end
  end

  describe '#preview' do
    let(:data) { "# Title\n\nSome **bold** copy that runs on for a while." }

    it 'strips the formatting' do
      expect(field.preview(length: 100)).to eq 'Title Some bold copy that runs on for a while.'
    end

    it 'truncates to the requested length' do
      expect(field.preview(length: 10).length).to be <= 10
    end

    context 'with a document longer than the preview source limit' do
      let(:data) { "start #{'filler ' * 5_000}MARKER" }

      it 'never reads past the limit, however long the requested preview' do
        expect(field.preview(length: 10_000)).not_to include('MARKER')
      end
    end

    context 'when the source limit is disabled' do
      let(:options) { { preview_source_limit: nil } }
      let(:data) { "a#{'b' * 2_000}" }

      it 'still truncates the output' do
        expect(field.preview(length: 20).length).to be <= 20
      end
    end

    context 'with a configured truncate_length' do
      let(:options) { { truncate_length: 5 } }

      it 'uses it as the default' do
        expect(field.preview.length).to be <= 5
      end
    end
  end

  describe '#html_id' do
    let(:data) { nil }
    let(:output) { field.html_id }

    context 'with a non-namespaced model' do
      before { stub_const 'Foo', Class.new }

      let(:options) { { resource: Foo.new } }

      it 'returns the expected HTML id' do
        expect(output).to eq 'foo_simple_markdown'
      end
    end

    context 'with a namespaced model' do
      before { stub_const 'Foo::Bar', Class.new }

      let(:options) { { resource: Foo::Bar.new } }

      it 'returns the expected HTML id' do
        expect(output).to eq 'foo_bar_simple_markdown'
      end
    end
  end
end
