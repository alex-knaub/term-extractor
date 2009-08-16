require "date"
require "rubygems"
require "sinatra"

$: << "lib"

require "term-extractor"

TE = TermExtractor.new

get '/' do
  haml :index
end

post '/' do
  if params[:extract]
    @text = params[:text]
    @terms = TE.extract_terms_from_text(@text)
  elsif params[:train]
    File.open("training/good", "a"){|o| o.puts params[:goodterms]}
    File.open("training/bad", "a"){|o| o.puts params[:badterms]}

    time = DateTime.now.strftime("%Y-%m-%d-%H:%M")
   
    File.open("test/examples/#{time}_spec.rb", "w"){ |o|
o.puts <<SPEC
TE = TermExtractor.new unless defined? TE

Text = <<TEXT
#{params[:text]}
TEXT

Terms = TE.extract_terms_from_text(Text).map{|x| x.to_s}.sort.uniq

describe "the example generated at #{time}" do
  it "should contain the following terms" do 
    #{(params[:goodterms] || "").split(/\r?\n/).map{|x| x.strip}.inspect}.each do |term|
      Terms.should include(term)
    end
  end

  it "should not contain the following terms" do 
    #{(params[:badterms] || "").split(/\r?\n/).map{|x| x.strip}.inspect}.each do |term|
      Terms.should_not include(term)
    end
  end
end

SPEC
    

    }
  end

  haml :index
end
