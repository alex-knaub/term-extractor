require "term-extractor/nlp"

class Term
  attr_accessor :pos, :sentence, :chunks, :tokens

  def initialize(tokens)
    @tokens = tokens
    yield self if block_given?
  end

  def to_s
    @to_s ||= TermExtractor.recombobulate_term(@tokens)
  end
end

# A class for extracting useful snippets of text from a document
class TermExtractor
  attr_accessor :nlp, :max_term_length, :remove_urls, :remove_paths

  def initialize(models = File.dirname(__FILE__) + "/../models")
    @nlp = NLP.new(models)

    # Empirically, terms longer than about 5 words seem to be either
    # too specific to be useful or very noisy.
    @max_term_length = 4 


    self.remove_urls = true
    self.remove_paths = true

    yield self if block_given?
  end

  
  # This class holds all the state needed for term calculations
  # on a single sentence. 
  # It uses chunking and part of speech tagging information to 
  # mark each token in the sentence as to whether it is allowed 
  # to start a term or end a term and whether terms can cross it
  # Terms are then calculated by simply looking for all sequences
  # of tokens up to the maximum length which meet these constraints.
  class TermContext
    attr_accessor :parent, :tokens, :postags, :chunks
    
    def nlp
      parent.nlp
    end

    def initialize(parent, sentence)
      @parent = parent
      sentence = NLP.clean_sentence(sentence)

      # User defineable cleaning.
      sentence = NLP.remove_urls(sentence) if parent.remove_urls
      sentence = NLP.remove_paths(sentence) if parent.remove_paths


      @tokens = NLP.tokenize_sentence(sentence)
      @postags = nlp.postagger.tag(tokens)
      @chunks = nlp.chunker.chunk(tokens, postags)


      @sentence = sentence

    end

    # This is the bit where all the work happens   
    def boundaries
      return @boundaries if @boundaries

      # To each token we assign three attributes which determine how it may occur within a term.
      # can_cross determines if this token can appear internally in a term
      # can_start determines if a term is allowed to start with this token
      # can_end determines if a term is allowed to end with this token
      @boundaries = tokens.map{|t| {}}

      @boundaries.each_with_index do |b, i|  
        # WARNING: It's important to only write boundaries for indices 
        # <= i. Otherwise the next loop iteration will overwrite the 
        # set value.
        

        tok = tokens[i]
        pos = postags[i]
        chunk = chunks[i]

        # Cannot cross commas or coordinating conjections (and, or, etc)
        b[:can_cross] = !(pos =~ /,/)

        # words which are extra double plus stop wordy and shouldn't appear inside
        # terms
        # FIXME: This is a hack. We're really hitting the limit of
        # rule based systems here
        b[:can_cross] &&= ![
          "after", 
          "where",
          "when",
          "for",
          "at",
          "to",
          "with"
        ].include?(tok)
 
        # Cannot cross the beginning of verb terms
        # i.e. we may start with verb terms but not include them
        b[:can_cross] = (chunk != "B-VP") if b[:can_cross]
        
        # We generate tags like <PATH>, <URL> and <QUOTE>
        # to encapsulate various sorts of noise strings. 
        b[:can_cross] &&= !(tok =~ /<\w+>/)

        # We are only allowed to start terms on the beginning of a term chunk
        b[:can_start] = (chunks[i] == "B-NP")

        # In some cases we want to move the start of a term to the right. These cases are:
        # - a determiner (the, a, etc)
        # - a posessive pronoun (my, your, etc) 
        # - comparative and superlative adjectives (best, better, etc.)
        # - A number. In this case note that starting with the number is also allowed. e.g. "two cities" will produce both "two cities"
        # In all cases we only do this for noun terms, and will only move them to internal points.
        if (chunks[i] == "I-NP") && (postags[i-1] =~ /DT|WDT|PRP|JJR|JJS|CD/)
            b[:can_start] = true 
        end

        # We must include any tokens internal to the current chunk
        b[:can_end] = !(chunks[i + 1] =~ /I-/)

        # We break phrases around coordinating conjunctions (and, or, etc)
        # but allow phrases that should rightfully be forced to continue past
        # the conjunction. e.g. in "nuts and bolts", we allow "nuts" and "bolts" 
        # but not the whole phrase. This is true even if this resolves as a single
        # chunk
        if pos == 'CC'
          @boundaries[i-1][:can_end] = true if i > 0        
          @boundaries[i][:can_cross] = false
        end   
        # need to do it here rather than in previous if statement
        # as otherwise the next pass along will overwrite the result
        # we set here.
        if i > 0 && @postags[i-1] == 'CC'
          @boundaries[i][:can_start] = true
        end

        # It is permitted to cross stopwords, but they cannot lie at the term boundary
        if (nlp.stopword? tok) || (nlp.stopword? tokens[i..i+1].join) # Need to take into account contractions, which span multiple tokens
          b[:can_end] = false
          b[:can_start] = false
        end

        # The presence of a ' at the start of a token is most likely an indicator that we've
        # split across a contraction. e.g. would've -> would 've. We are not allowed to 
        # cross this transition point.
        if tok =~ /^'/
          b[:can_start] = false
          @boundaries[i - 1][:can_end] = false
        end

        # Common sources of crap starting words
        b[:can_start] &&= !(pos =~ /CC|PRP|IN|DT|PRP\$|WP|WP\$|TO|EX|JJR|JJS/)

        # TODO: Is this still a good idea?
        b[:can_end] &&= (pos =~ /NN|NNS|NNP|NNPS|FW|CD/)

      end

      @boundaries
    end

    def terms
      return @terms if @terms

      @terms = []

      i = 0
      j = 0
      while(i < tokens.length)
        if !boundaries[i][:can_start] || !boundaries[i][:can_cross]
          i += 1
          next
        end

        j = i if j < i

        if (j == tokens.length) || !boundaries[j][:can_cross] || (j >= i + parent.max_term_length)
          i += 1
          j = i
          next
        end

        if !boundaries[j][:can_end]
          j += 1
          next
        end

        term = tokens[i..j]
        poses = postags.to_a[i..j]
        term = Term.new(term){ |it|
          it.pos = poses.join("-")
          it.chunks = chunks.to_a[i..j]
        }
        terms << term if TermExtractor.allowed_term?(term)

        j += 1
      end

      @terms
    end
  end

  # Extract all terms in a given sentence.
  def extract_terms_from_sentence(sentence)
    TermContext.new(self, sentence).terms
  end

  def extract_terms_from_text(text)
    if block_given?
      nlp.sentences(text).each_with_index do |s, i|
        terms = extract_terms_from_sentence(s);
        terms.each{|p| p.sentence = i; yield(p) }
      end
    else
      results = []
      extract_terms_from_text(text){ |p| results << p }
      results
    end
  end

  # Final post filter on terms to determine if they're allowed.
  def self.allowed_term?(p)
    return false if p.to_s =~ /^[^a-zA-Z]*$/ # We don't allow things which are just sequences of numbers
    return false if p.to_s.length > 255
    true
  end

  # Take a sequence of tokens and turn them back into a term. 
  def self.recombobulate_term(term)
    term = term.join(" ")
    term.gsub!(/ '/, "'")
    term.gsub!(/ \./, ".")
    term
  end

end
