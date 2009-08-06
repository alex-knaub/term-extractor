require "term-extractor"

PE = TermExtractor.new

PE.nlp.each_sentence(ARGF) do |sentence|
  puts PE.extract_terms_from_sentence(sentence)
end
