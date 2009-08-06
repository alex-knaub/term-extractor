require "term-extractor/nlp"

class Term
  attr_accessor :to_s, :pos, :sentence

  def initialize(ts, pos, sentence = nil)
    @to_s, @pos, @sentence = ts, pos, sentence
  end
end

class TermExtractor
  attr_accessor :nlp, :max_term_length, :proscribed_start, :required_ending, :remove_urls, :remove_paths

  def initialize(models = File.dirname(__FILE__) + "/../models")
    @nlp = NLP.new(models)

    # Empirically, terms longer than about 5 words seem to be either
    # too specific to be useful or very noisy.
    @max_term_length = 5

    # Common sources of crap starting words
    @proscribed_start = /CC|PRP|IN|DT|PRP\$|WP|WP\$|TO|EX/

    # We have to end in a noun, foreign word or number.
    @required_ending = /NN|NNS|NNP|NNPS|FW|CD/

    self.remove_urls = true
    self.remove_paths = true

    yield self if block_given?
  end


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
   
    def boundaries
      return @boundaries if @boundaries

      # To each token we assign three attributes which determine how it may occur within a term.
      # can_cross determines if this token can appear internally in a term
      # can_start determines if a term is allowed to start with this token
      # can_end determines if a term is allowed to end with this token
      @boundaries = tokens.map{|t| {}}

      @boundaries.each_with_index do |b, i|  
        tok = tokens[i]
        pos = postags[i]
        chunk = chunks[i]

        # Cannot cross commas or coordinating conjections (and, or, etc)
        b[:can_cross] = !(pos =~ /,|CC/)
  
        # Cannot cross the beginning of verb terms
        # i.e. we may start with verb terms but not include them
        b[:can_cross] = (chunk != "B-VP") if b[:can_cross]
        
        # We generate tags like <PATH>, <URL> and <QUOTE>
        # to encapsulate various sorts of noise strings. 
        b[:can_cross] &&= !(tok =~ /<\w+>/)

        # We are only allowed to start terms on the beginning of a term chunk
        b[:can_start] = (chunks[i] == "B-NP")
        if i > 0
          if postags[i-1] =~ /DT|WDT|PRP|JJR|JJS/
              # In some cases we want to move the start of a term to the right. These cases are:
              # - a determiner (the, a, etc)
              # - a posessive pronoun (my, your, etc) 
              # - comparative and superlative adjectives (best, better, etc.)
              # In all cases we only do this for noun terms, and will only move them to internal points.
              b[:can_start] ||= (chunks[i] == "I-NP")
              @boundaries[i - 1][:can_start] = false
          end
        end

        # We must include any tokens internal to the current chunk
        b[:can_end] = !(chunks[i + 1] =~ /I-/)

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
    
        # Must match the requirements for POSes at the beginning and end.      
        b[:can_start] &&= !(pos =~ parent.proscribed_start) 
        b[:can_end] &&= (pos =~ parent.required_ending) 

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
        term = Term.new(TermExtractor.recombobulate_term(term), poses.join("-"))
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
    return false if p.pos =~ /^CD(-CD)*$/ # We don't allow things which are just sequences of numbers
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
