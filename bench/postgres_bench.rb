# frozen_string_literal: true

# Measures what Markdown of a given length actually costs in Postgres: the
# stored size after TOAST compression, and the round-trip time to write and read
# one row. Answers "how long a document is it reasonable to put in this field?"
#
# Run with: bundle exec rake bench:postgres
require 'pg'
require_relative 'markdown_corpus'

DSN = ENV.fetch('BENCH_DATABASE_URL', 'postgres://postgres:bench@127.0.0.1:55432/bench')
REPETITIONS = Integer(ENV.fetch('REPETITIONS', '50'))

def ms(repetitions, &)
  started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  repetitions.times(&)
  (Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) / repetitions * 1_000
end

def commas(number)
  number.to_s.reverse.scan(/\d{1,3}/).join(',').reverse
end

connection = PG.connect(DSN)
connection.exec('DROP TABLE IF EXISTS bench_articles')
connection.exec('CREATE TABLE bench_articles (id serial primary key, body text)')

puts "PostgreSQL #{connection.exec('SHOW server_version').first['server_version']}, " \
     "#{REPETITIONS} iterations each"
puts
puts '| Document | In row (bytes) | Stored (bytes) | Compression | INSERT | SELECT |'
puts '|---|---|---|---|---|---|'

MarkdownCorpus.sizes.each do |size|
  document = MarkdownCorpus.document(size)

  connection.exec('TRUNCATE bench_articles')
  insert = ms(REPETITIONS) do
    connection.exec_params('INSERT INTO bench_articles (body) VALUES ($1)', [document])
  end

  id = connection.exec('SELECT max(id) AS id FROM bench_articles').first['id']
  select = ms(REPETITIONS) do
    connection.exec_params('SELECT body FROM bench_articles WHERE id = $1', [id])
  end

  stored = connection.exec_params(
    'SELECT pg_column_size(body) AS stored, octet_length(body) AS raw ' \
    'FROM bench_articles WHERE id = $1', [id]
  ).first

  puts format('| %s chars | %s | %s | %.1fx | %.3f ms | %.3f ms |',
              commas(size), commas(stored['raw'].to_i), commas(stored['stored'].to_i),
              stored['raw'].to_f / stored['stored'].to_i, insert, select)
end

puts
puts 'Postgres limits for a `text` column:'
puts format('- hard maximum per value: %s bytes (1 GB)', commas(1_073_741_824))
puts '- values over ~2 KB move out of the row into TOAST storage and are compressed'
puts '- there is no length limit to configure: `text`, `varchar` and `varchar(n)` ' \
     'store identically, `n` only adds a check'

connection.exec('DROP TABLE bench_articles')
connection.close
