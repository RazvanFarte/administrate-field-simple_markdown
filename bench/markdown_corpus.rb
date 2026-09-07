# frozen_string_literal: true

# Generates Markdown that looks like something a person would type into an
# admin form: headings, prose, emphasis, links, lists and quotes.
#
# The prose is assembled from a word list with a seeded PRNG rather than by
# repeating one paragraph. Repetition would make the Postgres numbers
# meaningless - TOAST compresses a repeated template roughly 25x, which no real
# document achieves.
module MarkdownCorpus
  WORDS = %w[
    account address amount balance batch billing bundle carrier catalogue channel
    charge checkout client column contract customer delivery discount document
    driver export field freight gateway history import invoice label ledger
    manifest merchant metric notice option order package parcel payment pickup
    policy price product profile quantity queue rate receipt record refund report
    request response return route schedule service shipment status summary
    supplier surcharge tariff template tracking transfer transport update vendor
    volume warehouse weight zone
  ].freeze

  SEED = 20_260_906

  module_function

  def document(characters)
    random = Random.new(SEED)
    text = +''
    section = 0

    text << paragraph(random, section += 1) while text.length < characters
    text[0, characters]
  end

  def paragraph(random, section)
    <<~MARKDOWN
      ## #{sentence(random, 4).capitalize}

      #{sentence(random, 28)}, with **#{words(random, 2)}** and _#{words(random, 2)}_.
      See [#{words(random, 3)}](https://example.com/docs/#{section}) or `#{words(random, 1)}`.

      - #{sentence(random, 8)}
      - #{sentence(random, 6)}, [linked](https://example.com/#{section})
      - #{sentence(random, 9)}

      > #{sentence(random, 14)}.

    MARKDOWN
  end

  def sentence(random, length)
    words(random, length)
  end

  def words(random, count)
    Array.new(count) { WORDS.sample(random: random) }.join(' ')
  end

  def sizes
    [1_000, 5_000, 10_000, 50_000, 100_000, 1_000_000]
  end
end
