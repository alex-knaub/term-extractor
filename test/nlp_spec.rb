require "term-extractor/nlp"
require "rubygems"
require "rake"

NLP = TermExtractor::NLP
MyNLP = NLP.new("#{File.dirname(__FILE__)}/../models")

def dont_split(text)
  # This might not be quite right. We're currently allowing stripping punctuation
  # from the beginning and end. Maybe we shouldn't?
  NLP.tokenize_sentence(text).map{|x| x.to_s}.should == [text] 
end


def one_sentence(text)
  MyNLP.sentences(text).should == [text]
end

def n_sentences(n, text)
  s = MyNLP.sentences(text)
  s.should have_exactly(n).sentences
end

describe "sentence splitting" do
  it "should not split sentences around URLs" do 
    one_sentence("If you go to http://www.google.com and type 'kitties' you will get lots of kitties")
  end

  it "should split sentences with abbreviations sensibly" do
    one_sentence("Dr. Smith likes kitties")
  end

  it "should produce two sentences when there are line breaks" do

    n_sentences 2, "Posting Date: November 8, 2008 \r\n Release Date: January, 1998\r\n \r\n Language: English"

    n_sentences 2, <<KITTIES
I like kitties

I like puppies
KITTIES
  end

end

describe "url removal" do
  it "should replace URLs in the middle of sentences" do
    NLP.remove_urls("I like the links you find at http://www.google.com when searching for kitties").should == "I like the links you find at <URL> when searching for kitties"
  end

  it "should replace URLs at the beginning of sentences" do
    NLP.remove_urls("http://www.google.com is your number one source for kitties").should == "<URL> is your number one source for kitties"
  end

  it "should replace URLs at the end of sentences" do 
    NLP.remove_urls("When I want kitties I go to http://www.google.com").should == "When I want kitties I go to <URL>"
  end

  it "shuold replace URLs between sentences" do
    NLP.remove_urls("The number one kitty finding service is http://www.google.com. Accept no substitutes").should == "The number one kitty finding service is <URL>. Accept no substitutes"
  end
end

describe "path removal" do 
  it "should remove windows style paths" do
    path ="C:\\Home\\Windows\\Nonsense\\Kitties is where windows people store kitty related material"

    NLP.remove_paths(path).should == "<PATH> is where windows people store kitty related material" 
  end

  it "should remove windows style paths with spaces in them" do 
    path = "C:\\Documents and Settings\\Kitty is the kitty's home directory"

    NLP.remove_paths(path).should == "<PATH> is the kitty's home directory"    
  end

  it "should remove unix style paths" do 
    NLP.remove_paths("/home/david/kitties is where *I* store kitty related material").should == "<PATH> is where *I* store kitty related material"
  end
end

describe "extracting embedded terms" do
  it "should replace quotes with <QUOTE>" do 
    quote = "\"I like kitties\", she declared"

    main, embedded = NLP.extract_embedded_sentences(quote)
  
    main.should == "<QUOTE>, she declared"
    embedded.should == "I like kitties" 
  end


  it "should replace parenthetical comments with an empty string" do 
    main, embedded = NLP.extract_embedded_sentences("I like kitties (especially fuzzy ones)")

    main.should == "I like kitties "
    embedded.should == "especially fuzzy ones"
  end

  it "should correctly deal with multiple nested parenthetical comments" do
    main, e1, e2 =  NLP.extract_embedded_sentences("I like kitties (especially fuzzy ones (but the long haired ones are kinda ugly))")

    main.should == "I like kitties "
    e1.should == "but the long haired ones are kinda ugly"
    e2.should == "especially fuzzy ones "
  end

  it "should correctly deal with multiple non nested parenthetical comments" do 
    main, e1, e2 =  NLP.extract_embedded_sentences("I like kitties (especially fuzzy ones)(but the long haired ones are kinda ugly)")

    main.should == "I like kitties "
    e1.should == "especially fuzzy ones"
    e2.should == "but the long haired ones are kinda ugly"
  end

  it "should not extract a subterm when it is not matched" do 
    NLP.extract_embedded_sentences("She declared \" I like kitties").should have(1).fragment
  end  

  it "should not extract a subterm when it would have to span multiple lines to do so " do 
kitties = <<KITTIES    
I like kitties (they are
the best)  
KITTIES

    NLP.extract_embedded_sentences(kitties).should == [kitties]
  end

end

describe "tokenization" do
 
  it "should not split up URLs" do
    dont_split("http://www.theonion.com/content/news/female_serial_killer_has_to_work")
  end

  it "should not split up URLs with -s in them" do 
    dont_split("http://www.amazon.com/Fierce-Conversations-Acheiving-Success-Conversation/dp/0670031240")
  end

  it "should not split up emails" do
    dont_split("david.maciver@trampolinesystems.com")
  end

  it "should split up contractions" do
    NLP.tokenize_sentence("I'm the very model of a modern major general").should == ["I", "'m", "the", "very", "model", "of", "a", "modern", "major", "general"]
  end

  it "should split sentences around ellipses" do
    NLP.tokenize_sentence("I like kitties...puppies are ok too").should == ["I", "like", "kitties", ",", "puppies", "are", "ok", "too"]
  end

  it "shouldn't split paths containing .." do
    dont_split("/home/david/cute/puppies/../kitties/pictures")
  end

  it "should pull a sentence terminator into its own token" do 
    NLP.tokenize_sentence("You don't like kitties?!?")[-1].should == "?!?"
  end

  it "should detach punctuation as a separate token" do
    NLP.tokenize_sentence("babies... the other white meat")[1].should == "..."
  end

  def dont_produce_token(text, term)  
    tokens = NLP.tokenize_sentence(text)  
    tokens.should_not include(term)
  end

  it "should not split numbers around commas" do
    dont_produce_token("the reasons for selecting opengl rather than prefuse were to visualise >10,000 nodes and do 3d", "000")
  end 

  it "should pull commas off the ends of tokens" do
    dont_produce_token("kitties, puppies and birdies are all cute", "kitties,")
  end

end

describe "cleaning" do
  it "should remove stars trailing or leading a word" do
    NLP.clean_sentence("Should that really take 5 minutes *over a network*").should == "Should that really take 5 minutes , over a network"
  end


  it "should turn quotes into commas" do
    NLP.clean_sentence("I read \"Why kitties are cute\" over the summer").should == "I read , Why kitties are cute , over the summer"
  end

  it "should remove all new lines" do 
    (NLP.clean_sentence("
      This sentence
      has lots of 
      line breaks
      in it
    ") =~ /\n|\./).should == nil
  end
end

def equate(foo, bar)
  MyNLP.canonicalize(foo).should == MyNLP.canonicalize(bar)
end

describe "canonicalization" do
  it "should identify plurals" do
    equate("kitties", "kitty")
  end

  it "should identify strings that differ only in non alphanumeric characters" do
    equate("foo/bar/baz", "foo bar baz")
  end

  it "should be insensitive to order" do
    equate("foo bar baz", "bar foo baz")
  end

  it "should ignore stopwords" do 
    equate("programming in java", "java programming")
  end
end

describe "stopword detection" do
  it "should mark a as a stopword" do
    MyNLP.stopword?("a").should be(true)
  end

  it "should not be fooled by capitalisation" do
    MyNLP.stopword?("A").should be(true)
  end
end
