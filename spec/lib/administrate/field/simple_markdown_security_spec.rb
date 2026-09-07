# frozen_string_literal: true

require 'spec_helper'
require 'erb'
require 'nokogiri'

# #to_html marks its result html_safe, so this file is the evidence that doing
# so is justified. Each payload is rendered and the resulting DOM is inspected
# for the things that actually execute: script elements, event-handler
# attributes, and scripting URL schemes.
DANGEROUS_SCHEMES = /\A\s*(javascript|vbscript|data):/i

PAYLOADS = {
  'script element' => '<script>alert(1)</script>',
  'img event handler' => '<img src=x onerror=alert(1)>',
  'svg event handler' => '<svg onload=alert(1)>',
  'body event handler' => '<body onload=alert(1)>',
  'iframe' => '<iframe src="javascript:alert(1)"></iframe>',
  'object' => '<object data="javascript:alert(1)"></object>',
  'style element' => '<style>@import "javascript:alert(1)";</style>',
  'inline handler on anchor' => '<a href="#" onclick="alert(1)">x</a>',
  'javascript link' => '[click](javascript:alert(1))',
  'mixed case scheme' => '[click](JaVaScRiPt:alert(1))',
  'entity encoded scheme' => '[click](java&#115;cript:alert(1))',
  'whitespace broken scheme' => "[click](java\tscript:alert(1))",
  'leading space scheme' => '[click]( javascript:alert(1))',
  'data uri document' => '[click](data:text/html;base64,PHN2Zz48L3N2Zz4=)',
  'vbscript link' => '[click](vbscript:msgbox(1))',
  'image with javascript source' => '![x](javascript:alert(1))',
  'quote escape in image alt' => '![" onerror="alert(1)](https://example.test/x.png)',
  'quote escape in link title' => '[x](https://example.test "\" onmouseover=\"alert(1)")',
  'quote escape in heading anchor' => '# heading" onmouseover="alert(1)',
  'reference link with scheme' => "[a][b]\n\n[b]: javascript:alert(1)",
  'autolinked scheme' => 'javascript:alert(1)',
  'html comment smuggling' => '<!-- --><script>alert(1)</script>',
  'nested markdown in html' => '<div><script>alert(1)</script></div>'
}.freeze

RSpec.describe Administrate::Field::SimpleMarkdown do
  def render(payload, options = {})
    field = described_class.new(:body, payload, :show)
    field.define_singleton_method(:options) { options }
    field.to_html
  end

  def scripting_vectors(html)
    document = Nokogiri::HTML5.fragment(html)
    vectors = []

    vectors.concat(document.css('script, iframe, object, embed, style').map(&:name))
    document.css('*').each do |node|
      node.attribute_nodes.each do |attribute|
        vectors << "#{node.name}[#{attribute.name}]" if attribute.name.start_with?('on')
        vectors << "#{node.name}[#{attribute.name}]" if attribute.value.match?(DANGEROUS_SCHEMES)
      end
    end

    vectors
  end

  context 'with the default options' do
    PAYLOADS.each do |name, payload|
      it "renders no scripting vector for #{name}" do
        expect(scripting_vectors(render(payload))).to be_empty
      end
    end
  end

  context 'with filter_html turned off' do
    PAYLOADS.each do |name, payload|
      it "sanitizes #{name} rather than trusting it" do
        expect(scripting_vectors(render(payload, filter_html: false))).to be_empty
      end
    end

    it 'keeps the HTML that was the reason for turning filter_html off' do
      expect(render('<em>kept</em>', filter_html: false)).to include('<em>kept</em>')
    end
  end

  context 'with sanitizing explicitly disabled' do
    it 'is documented as unsafe, and behaves that way' do
      html = render('<script>alert(1)</script>', filter_html: false, sanitize: false)

      expect(scripting_vectors(html)).to include('script')
    end
  end

  # StripDown passes literal HTML source through untouched, so "<script>" in a
  # document comes back as the characters "<script>". That is safe only because
  # the value is an ordinary String: ERB escapes it on the way into the page,
  # and the index partial relies on exactly that.
  describe 'the plain text renderings' do
    let(:field) { described_class.new(:body, '<script>alert(1)</script>', :index) }

    it 'returns #to_s as an unsafe string that Rails will escape' do
      expect(field.to_s).not_to be_html_safe
    end

    it 'returns #preview as an unsafe string that Rails will escape' do
      expect(field.preview(length: 200)).not_to be_html_safe
    end

    it 'escapes the markup when the index partial renders it' do
      escaped = ERB::Util.html_escape(field.preview(length: 200))

      expect(escaped).to include('&lt;script&gt;')
      expect(escaped).not_to include('<script>')
    end
  end

  describe '#to_html' do
    it 'is marked html_safe, which is what the payload corpus above justifies' do
      expect(described_class.new(:body, '**x**', :show).to_html).to be_html_safe
    end
  end
end
