TE = TermExtractor.new unless defined? TE

Text = <<TEXT
As the healthcare debate picks up pace, I find myself being asked with increasing regularity what I think of Britain’s healthcare system.  Six months ago, I’d have jumped into the answer with gusto, but these days…  I don’t know, I am just so fatigued by all the fear-mongering and hysteria, the ignorance and the downright idiocy of the current debate that I can hardly summon the energy to add my voice to the cacophony.
TEXT

Terms = TE.extract_terms_from_text(Text).map{|x| x.to_s}.sort.uniq

describe "the example generated at 2009-08-16-14:41" do
  it "should contain the following terms" do 
    ["healthcare debate", "Britain's healthcare system", "Six months", "answer", "gusto", "fear-mongering", "hysteria", "ignorance", "downright idiocy", "current debate", "energy", "voice", "cacophony"].each do |term|
      Terms.should include(term)
    end
  end

  it "should not contain the following terms" do 
    ["increasing regularity", "days\342\200\246", "voice to the cacophony", "answer with gusto"].each do |term|
      Terms.should_not include(term)
    end
  end
end

