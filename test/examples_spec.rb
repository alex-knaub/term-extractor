require "term-extractor"

PE = TermExtractor.new unless defined? PE

Diagrams = <<DIAGRAMS
I think having nice standardised diagrams of stuff like that is REALLY
useful. One OO architect drops dead and your replacement walks in and
can pick up the documents and read them because they already speak
that language. That's a great thing. I sort of wish it had been pushed
as being that -- a lingua franca for documenting designs.
DIAGRAMS


describe "Diagram terms" do


end

Murray = <<MURRAY
The MCHS Department of Music is one of the most distinguished music programs in the State, having an award-winning choral and band program. The Marching Indians, under the direction of Mr. Mike Weaver, have performed all over the country, most recently at Universal Studios in Orlando, Disney World and the St. Patrick's Day Parade in New York City. Since 1958, the Marching Indians have been entreating fans with exciting, visually stimulating shows and their trademark deep, loud sound. Recently the Marching Indians received the Grand Championship at the 2008 Golden River Music Festival and won the first ever US101 radio battle of the bands receiving a concert by the Eli Young Band. Many students from MCHS Department of Bands have been involved with All District and All State bands as well as various summer clinics, orchestras and even the Georgia Lions All State Band.
MURRAY
MurrayTerms = PE.extract_terms_from_text(Murray).map{|x| x.to_s}

describe "Murray terms" do
  it "should get Mike's name right" do
    MurrayTerms.should_not include("Mr . Mike Weaver")
    MurrayTerms.should include("Mr. Mike Weaver")
  end
end

Chromosome = <<CHROM
Humans have 23 pairs of chromosomes packed with genes that dictate every aspect of our biological functioning. Of these pairs, the sex chromosomes are different; women have two X chromosomes and men have an X and a Y chromosome. The Y chromosome contains essential blueprints for the male reproductive system, in particular those for sperm development.

But the Y chromosome, which once contained as many genes as the X chromosome, has deteriorated over time and now contains less than 80 functional genes compared to its partner, which contains more than 1,000 genes. Geneticists and evolutionary biologists determined that the Y chromosome's deterioration is due to accumulated mutations, deletions and anomalies that have nowhere to go because the chromosome doesn't swap genes with the X chromosome like every other chromosomal pair in our cells do. 
CHROM

ChromosomeTerms = PE.extract_terms_from_text(Chromosome).map{|x| x.to_s}

describe "Chromosome terms" do
  it "should say nothing about what humans have" do
    ChromosomeTerms.should_not include("Humans have 23 pairs")
  end

  it "knows about the male reproductive system, if you know what I mean" do 
    ChromosomeTerms.should include("male reproductive system")
    ChromosomeTerms.should include("sperm development")
  end

  it "is about humans" do 
    ChromosomeTerms.should include("Humans")
  end
end

Environment = "Please consider the environment before printing this e-mail"
EnvironmentTerms = PE.extract_terms_from_text(Environment).map{|x| x.to_s}.sort

describe "Environment terms" do
  it "is about email" do 
    EnvironmentTerms.should include("e-mail")
  end
end

Apollo = <<APOLLO
Fate has ordained that the men who went to the moon to explore in peace will stay on the moon to rest in peace.

These brave men, Neil Armstrong and Edwin Aldrin, know that there is no hope for their recovery. But they also know that there is hope for mankind in their sacrifice.

These two men are laying down their lives in mankind's most noble goal: the search for truth and understanding.

They will be mourned by their families and friends; they will be mourned by their nation; they will be mourned by the people of the world; they will be mourned by a Mother Earth that dared send two of her sons into the unknown.

In their exploration, they stirred the people of the world to feel as one; in their sacrifice, they bind more tightly the brotherhood of man.

In ancient days, men looked at stars and saw their heroes in the constellations. In modern times, we do much the same, but our heroes are epic men of flesh and blood.

Others will follow, and surely find their way home. Man's search will not be denied. But these men were the first, and they will remain the foremost in our hearts.
APOLLO

ApolloTerms = PE.extract_terms_from_text(Apollo).map{|x| x.to_s}.sort.uniq

describe "Apollo terms" do
  it "knows of Neil and Buzz" do
    ApolloTerms.should include("Neil Armstrong")
    ApolloTerms.should include("Edwin Aldrin")
  end

  it "knows of where they've been" do
    ApolloTerms.should include("moon")
  end

  it "knows of times past and present" do
    ApolloTerms.should include("ancient days")
    ApolloTerms.should include("modern times")
  end

  it "knows of destiny" do
    ApolloTerms.should include("Fate")
  end

  it "knows of searching" do
    ApolloTerms.should include("exploration")
    ApolloTerms.should include("search")
    ApolloTerms.should include("Man's search")
  end

  it "knows not of mourning, but of courage and sacrifice" do
    ApolloTerms.should_not include("mourned")
    ApolloTerms.should include("brave men")
    ApolloTerms.should include("sacrifice")
  end

  it "knows of brotherhood" do 
    ApolloTerms.should include("brotherhood of man")
  end

  it "knows of mankind, and of its heroes" do
    ApolloTerms.should include("man")
    ApolloTerms.should include("men")
    ApolloTerms.should include("mankind")
    ApolloTerms.should include("heroes")
    ApolloTerms.should include("epic men")
  end

  it "looks to the stars from the earth" do
    ApolloTerms.should include("stars")
    ApolloTerms.should include("constellations")
    ApolloTerms.should include("Mother Earth")
    ApolloTerms.should include("world")
  end

end

Tweets = <<TWEETS
Playing around with meetup.com. Trying to remember why I didn't do more than look at it last time I discovered it: Seems great so far.
I'm bored. Anyone around London want to do something?
Suddenly realised that my twitter project was heading towards the dark side at an alarming rate. Time to scupper that plan....
@eisokant I kinda need this information to be as accurate as possible. I'll probably have to fetch the sender's tweet history. Sigh.
@eisokant It's not user ids that are problematic. It's that the returned results don't have information about which tweets they reply to. 
Is there any way to get in_reply_to details in the search API? If not, this project just became substantially more annoying. :-(
TWEETS

TweetTerms = PE.extract_terms_from_text(Tweets).map{|x| x.to_s}.sort.uniq

describe "TweetTerms" do 
  it "should not include blank strings" do
    TweetTerms.should_not include("")
    TweetTerms.should_not include(" ")
  end
end

Scala = "Scala is a multi-paradigm programming language designed to integrate features of object-oriented programming and functional programming"


ScalaTerms = PE.extract_terms_from_text(Scala).map{|x| x.to_s}.sort.uniq

describe "Scala terms" do
  it "should be functional" do
    ScalaTerms.should include("functional programming")
  end

  it "should be object-oriented" do
    ScalaTerms.should include("object-oriented programming")
  end
end
