# frozen_string_literal: true

# Measures what a Markdown field costs on the server: rendering one document to
# HTML (show page), stripping one to plain text (index page), and the preview
# path that only reads the start of the source.
#
# Run with: bundle exec ruby bench/redcarpet_bench.rb
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'administrate-field-easymde'
require_relative 'markdown_corpus'

REPETITIONS = Integer(ENV.fetch('REPETITIONS', '200'))

def field_for(source, options = {})
  Administrate::Field::SimpleMarkdown.new(:body, source, :show, options)
end

# Monotonic rather than the benchmark gem: it left the default gems in Ruby 4.0
# and this needs nothing it provides.
def measure(repetitions, &)
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  # A fresh field per iteration: Administrate builds one per row, per request.
  repetitions.times(&)
  (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) / repetitions * 1_000
end

puts "Ruby #{RUBY_VERSION}, Redcarpet #{Redcarpet::VERSION}, #{REPETITIONS} iterations each"
puts
puts '| Document | #to_html (show) | #to_s (full strip) | #preview (index) | to_html chars/ms |'
puts '|---|---|---|---|---|'

results = {}
MarkdownCorpus.sizes.each do |size|
  source = MarkdownCorpus.document(size)
  repetitions = size > 100_000 ? [REPETITIONS / 20, 5].max : REPETITIONS

  to_html = measure(repetitions) { field_for(source).to_html }
  to_s = measure(repetitions) { field_for(source).to_s }
  preview = measure(repetitions) { field_for(source).preview }

  results[size] = { to_html: to_html, to_s: to_s, preview: preview }
  puts format('| %s chars | %.3f ms | %.3f ms | %.3f ms | %d |',
              size.to_s.reverse.scan(/\d{1,3}/).join(',').reverse,
              to_html, to_s, preview, (size / to_html).round)
end

puts
puts '### Index page: 25 rows x N Markdown columns'
puts
puts '| Document per cell | Columns | #preview total | #to_s total (what 0.7.0 did) |'
puts '|---|---|---|---|'

[1_000, 10_000].each do |size|
  [1, 3, 5].each do |columns|
    cells = 25 * columns
    puts format('| %s chars | %d | %.1f ms | %.1f ms |',
                size.to_s.reverse.scan(/\d{1,3}/).join(',').reverse,
                columns,
                results[size][:preview] * cells,
                results[size][:to_s] * cells)
  end
end
