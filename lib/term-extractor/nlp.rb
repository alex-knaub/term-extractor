require "fileutils"
require "java"
require "term-extractor/opennlp-tools"
require "term-extractor/maxent-2.5.2"
require "term-extractor/trove"
require "term-extractor/snowball"
require "set"

class TermExtractor 
  # NLP contains a lot of general NLP related utilities.
  # In particular it contains: 
  # - a selection of OpenNLP classes
  # - a snowball stemmer
  # - a stopword list
  #
  # And various utilities built on top of these.
  class NLP 
    JV = Java::OpennlpToolsLangEnglish
    include_class("org.tartarus.snowball.ext.englishStemmer") { |x, y| "EnglishStemmer" }

    def stem(word)
      stemmer.setCurrent(word)
      stemmer.stem
      stemmer.getCurrent 
    end

    def sentdetect 
      @sentdetect ||= JV::SentenceDetector.new(loc("sd.bin.gz"))
    end

    def tagdict
      @tagdict ||= Java::OpennlpToolsPostag::POSDictionary.new(loc("tagdict"), true)
    end

    def postagger
      @postagger ||= JV::PosTagger.new(loc("tag.bin.gz"), tagdict)
    end

    def chunker
      @chunker ||= JV::TreebankChunker.new(loc("chunk.bin.gz"))
    end

    def stopwords 
      @stopwords
    end
    
    def stemmer 
      @stemmer ||= EnglishStemmer.new 
    end 

   
    def initialize(models)
      @models = models
      @stopwords = Set.new
      
      File.open(loc("stopwords")).each_line do |l|
        l.gsub!(/#.+$/, "")
        @stopwords.add clean_for_stopword(l) 
      end
    end

    # Canonicalisation gives a string that in some sense captures the "essential character"
    # of a piece of text. It normalizes it by removing unneccessary words, rearranging, and 
    # stripping suffixes. 
    # It is not itself intended to be a useful representation of the string, but instead for
    # determining if two strings are equal.
    def canonicalize(str)
      str.
        to_s.
        downcase.
        gsub(/[^\w\s]/, " ").
        split.
        select{|p| !stopword?(p)}.
        map{|p| stem(p) }.
        sort.
        join(" ")
    end

    def stopword?(word) 
      stopwords.include?(clean_for_stopword(word))
    end

    # Once we have split sentences, we clean them up prior to tokenization. We remove or normalize
    # a bunch of noise sources and get it to a form where distinct tokens are separated by whitespace.
    def NLP.clean_sentence(text)
      text = text.dup    
      text.gsub!(/--+/, " -- ") # TODO: What's this for? 

      text.gsub!(/…/, "...") # expand ellipsis character

      # Normalize bracket types.   
      # TODO: Shouldn't do this inside of tokens.
      text.gsub!(/{\[/, "(") 
      text.gsub!(/\}\]/, ")")
    
      # We turn most forms of punctuation which are not internal to tokens into commas
      punct = /(\"|\(|\)|;|-|\:|-|\*|,)/

      # Convert cunning "smart" apostrophes into plain old boring 
      # dumb ones.
      text.gsub!(/’/, "'")

      text.gsub!(/([\w])\.\.+([\w])/){ "#{$1} , #{$2}"}
      text.gsub!(/(^| )#{punct}+/, " , ")
      text.gsub!(/#{punct}( |$)/, " , ")
      text.gsub!(/(\.+ |')/){" #{$1}"}

      separators = /\//

      text.gsub!(/ #{separators} /, " , ")

      # We can be a bit overeager in turning things into commas, so we clear them up here
      # In particular we remove any we've accidentally added to the end of lines and we collapse
      # consecutive ones into a single one. 
      text.gsub!(/(,|\.) *,/){ " #{$1} " }
      text.gsub!(/(,| )+$/, "")
      text.gsub!(/^(,| )+/, "")

      text.gsub!(/((?:\.|\!|\?)+)$/){" #{$1}" }

      # Clean up superfluous whitespace 
      text.gsub!(/\s+/, " ")
      text
    end

    def NLP.tokenize_sentence(string)
      clean_sentence(string).split
    end

    Ending = /(!|\?|\.)+/

    def self.clean_text(text)
      text = text.gsub(/\r(\n?)/, "\n") # Evil microsoft line endings, die die die!
      text.gsub!(/^\s+$/, "") # For convenience, remove all spaces from blank lines
      text.gsub!(/\n\n+/m, ".\n.\n") # Collapse multiple line endings into periods
      text.gsub!(/\n/, " ") # Squash the text onto a single line.
      text.gsub!(/(\d+)\. /){ "#{$1} . " } # We separate out things of the form 1. as these are commonly lists and OpenNLP sentence detection handles them badly
      text.strip!
      text
    end

    def self.remove_urls(text)    
      text.gsub(/\w+:\/\/[^\s]+?(?=\.?(?= |$))/, "<URL>")
    end

    def self.remove_paths(text)
      text = text.clone

      # Fragments of windows paths
      text.gsub!(/[\w:\\]*\\[\w:\\]*/, "<PATH>")

      # fragments of unix paths
      text.gsub!(/\/[\w\/]+/, "<PATH>")
      text.gsub!(/[\w\/]+\//, "<PATH>")
   
      while text.gsub!(/<PATH>\s+\w+\s+<PATH>/, "<PATH>")
        # concatenate fragments where we have e.g. <PATH> and <PATH>
        # into single paths. This is to take into account paths containing spaces.
      end
      
      text.gsub!(/<PATH>(\s*<PATH)*/, "<PATH>")
      text
    end

    EmbedBoundaries = [
      ["\"", "\""],
      ["(", ")"],
      ["[", "]"],
      ["{", "}"]
    ].map{|s| s.map{|x| Regexp.quote(x) }}

    # Normalise a sentence by removing all parenthetical comments and replacing all embedded quotes contained therein
    # Return an array of the sentence and all contained subterms 
    def self.extract_embedded_sentences(text)
      text = text.clone
      fragments = [text]

      l = nil
      begin
        l = fragments.length

        EmbedBoundaries.each do |s, e|
          replace = if s == e then "<QUOTE>" else "" end
          matcher = /#{s}[^#{s}#{e}\n]*#{e}/
          text.gsub!(matcher) { |frag| fragments << frag[1..-2]; replace }
        end

      end while fragments.length > l

      if fragments.length > 1
        fragments = fragments.map{|f| extract_embedded_sentences(f) }.flatten
      end
      
      fragments
    end

    def sentences(string)
      sentdetect.sentDetect(NLP.clean_text(string)).to_a.map{|s| s.strip }.select{|s| (s.length > 0) && !(s =~ /^(\.|!|\?)+$/) }
    end

    def each_sentence(source)
      lines = []

      process_lines = lambda{
        text = lines.join("\n").strip 
        if text != ""
          sentences(text).each{|s| yield(s.gsub("\n", " ")) }
        end
        lines = []
      }

      source.each_line do |line|
        line = line.strip
    
        if line == ""   
          process_lines.call   
        end

        lines << line
      end

      process_lines.call
    end

    def postag(tokens)
      if tokens.is_a? String
        tokens = NLP.tokenize_sentence(tokens)
      else
        tokens = tokens.to_a
      end
      tokens.zip(postagger.tag(tokens).to_a) 
    end

    def chunk_text(text)
      result = []
      sentences(text).each{|x| result += chunk_sentence(x)} 
      result
    end

    def chunk_sentence(sentence)
      tokens = NLP.tokenize_sentence(sentence)
      postags = postagger.tag(tokens)
      tokens.zip(chunker.chunk(tokens, postags).to_a) 
    end
    
    private
    def loc(file)
      File.join(@models, file)
    end

    def clean_for_stopword(word)
      word.downcase.gsub(/[^\w]/, "")
    end

    def chunk_type(tag)
      case tag 
        when "O"  
          "O"
        when /B-(.+)$/
          $1
      end
    end
  end
end
