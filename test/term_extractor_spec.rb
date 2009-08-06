require "term-extractor"
require "rubygems"
require "rake"

PE = TermExtractor.new

def each_tag_in(file)
  PE.extract_terms_from_text(IO.read(file)).each do |tag|
    yield(tag)
  end
end

def each_tag(&blk) 
  FileList["test/files/*"].each { |f| each_tag_in(f, &blk) }
end

describe TermExtractor do
  it "should only return themes ending in nouns" do
    each_tag do |tag|
      tag.pos.should =~ /(^|-)(#{PE.required_ending})$/
    end
  end

  it "must not return themes starting with proscribed parts of speech" do
    each_tag do  |tag|
      tag.pos.should_not =~ /^(#{PE.proscribed_start})($|-)/
    end
  end

  it "should produce at least as many tags as words" do
    each_tag do |tag|
      tag.pos.split("-").length.should be >= tag.to_s.split.length
    end
  end 

  it "should correctly identify the subterms of a known term" do
    PE.extract_terms_from_text("I am a big fan of kitties").map{|x| x.to_s}.sort.should == ["big fan", "big fan of kitties", "kitties"]
  end

  it "should allow terms ending in numerals" do
    PE.extract_terms_from_text("I think Enterprise 2.0 is neato").map{|x| x.to_s}.sort.should == ["Enterprise 2.0"]  
  end

  it "should not concatenate words" do 
    internalconfig = <<PC
knowing their
internal network config
PC

    (PE.extract_terms_from_text(internalconfig).join(" ") =~ /theirinternal/).should be(nil)
  
  end

  it "should not concatenate words, even after ellipses" do 
    oukc = "Oracle University Knowledge Center...               http://www.oracle.com/education/oln"

  (PE.extract_terms_from_text(oukc).join(" ") =~ /Centerhttp/).should be(nil)
  end
  
  it "should not split contractions" do 
    terms = PE.extract_terms_from_sentence("It is my considered opinion that Jon should've liked the puppies").map{|x| x.to_s }

    terms.should_not include("ve")
    terms.should_not include("ve liked the puppies")
  end

  it "shouldn 't leave spaces in terms containing contractions" do
    terms = PE.extract_terms_from_sentence("Kittens aren't villains, they're cute").map{|x| x.to_s }

    terms.should include("Kittens aren't villains")
    terms.should_not include("Kittens aren 't villains")
  end

  def number_of_sentences(text, n)
    counts = [0] * n
    PE.extract_terms_from_text(text).each{|p| counts[p.sentence] += 1 }
    counts.should_not include(0)
  end

  it "should correctly attribute terms to sentences" do
    number_of_sentences("I like kitties", 1)
    number_of_sentences("I like kitties. They are cute creatures", 2)
  end

  it "should not start terms with contractions" do 
    terms = PE.extract_terms_from_sentence("But I don't have time for such a drastic rewrite right now, I'm thinking it would take at least two weeks for someone who is experienced with Eclipe editors").map{|x| x.to_s}
    
    terms.should_not include("don't have time")
  end

  it "should not produce terms which consist entirely of numbers" do
    text = <<BINARYSOLO    
Binary solo
0000001
00000011
0000001
00000011
0000001
0000001
0000001
0000001
BINARYSOLO

    PE.extract_terms_from_text(text).each{|p| p.to_s.should_not match(/^[\s\d]*$/) }
  end

  it "should pick out interesting nouns which follow a possessive" do 
    PE.extract_terms_from_sentence("You know, you could always have asked me to change your password...").map{|x| x.to_s}.should include("password")
  end

  it "should never generate stopwords" do 
    PE.extract_terms_from_sentence('A "Today Only" or "Sneak Preview" special tied to a specific day or time frame will encourage many recipients to open the message right away instead of passing it over for another one in the inbox.').map{|x| x.to_s}.should_not include("A")
  end

  it "should never generate URLs" do
    PE.extract_terms_from_text("I like http://www.google.com for searching").map{|t| t.to_s }.should_not include("http://www.google.com")
  end

  it "should not generate verb terms" do 
    PE.extract_terms_from_text("Do you think it makes sense to be the very model of a modern major general?").map{|t| t.to_s }.should_not include("makes sense")
  end


  it "should not allow verb terms internally" do
    PE.extract_terms_from_text("Please consider the environment before printing this email").map{|t| t.to_s }.should_not include("environment before printing this email")
  end

  it "should not start terms with comparison adjectives" do
    terms = PE.extract_terms_from_sentence("European policymakers urged the U.S. Senate on Wednesday to approve a revised $700 billion financial rescue plan aimed at tackling the worst financial crisis since the 1930s.").map{|t| t.to_s}
    terms.should_not include("worst financial crisis") 
    terms.should include("financial crisis") 

  end

  it "should not be confused by smart apostrophes" do
    PE.extract_terms_from_sentence("By training I’m a mathematician, but I seem to have drifted away from that and become a programmer.").each { |term|
      term.to_s.should_not =~ /’|'/
    }
  end
end
