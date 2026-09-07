# frozen_string_literal: true

require_relative '../../../bench/markdown_corpus'

# One article with hostile Markdown, so the browser suite can check how it is
# displayed, and one with a full-length document in every field, so the browser
# benchmark can measure an editor that has content in it.
HOSTILE_MARKDOWN = <<~MARKDOWN
  # Seeded article

  **bold** and _italic_ and a <script>alert('stored')</script> element.

  <img src=x onerror="window.__xssFromShowPage = true">

  [a link](javascript:alert('link'))
MARKDOWN

Article.find_or_initialize_by(title: 'Seeded article').tap do |article|
  article.body_1 = HOSTILE_MARKDOWN
  article.save!
end

BENCH_BODY_CHARS = Integer(ENV.fetch('BENCH_BODY_CHARS', '10000'))

Article.find_or_initialize_by(title: 'Benchmark article').tap do |article|
  next if article.persisted? && article.body_1.to_s.length == BENCH_BODY_CHARS

  document = MarkdownCorpus.document(BENCH_BODY_CHARS)
  Article::MARKDOWN_ATTRIBUTES.each { |attribute| article[attribute] = document }
  article.save!
end
