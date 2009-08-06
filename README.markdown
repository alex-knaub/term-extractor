# The Trampoline Systems term extractor

## Introduction

The term extractor is a library for taking natural text and extracting a
set of terms from it which make sense without additional context. For example, feeding it the following text from my home page:

    Hi. I’m David.

    I’m also various other things. By training I’m a mathematician, 
    but I seem to have drifted away from that and become a programmer, 
    currently working on natural language processing and social analytic
    software at Trampoline Systems.

    This site is my public face on the internet. It contains my blog, 
    my OpenID and anything else I want to share with the world. 

We get the following terms:

    David
    training
    mathematician
    programmer
    natural language processing
    social analytic software
    Trampoline Systems
    site
    public face
    public face on the internet
    internet
    blog
    world
 
No attempt is made to assign meaning to the terms: They're not guaranteed to represent the content of the document. They're just intended to be coherent snippets of text which you can reuse in a broader context.

One limitation of this is that it doesn't necessarily extract all reasonable terms. For example "natural language" is a reasonable term for this text which is not included in this. The way we use the term extractor at trampoline is to build a vocabulary of terms we consider interesting and then performing literal string searching for this term - this allows us to be selective in what terms we generate and permissive in looking for matches for them.

Currently only english is supported. There are plans to support other languages, but nothing is implemented in that regard: It requires someone who is native to that language, a competent programmer and at least passingly familiar with NLP, so understandably we're a bit resource constrained on getting wide spread non-english support. 

## Usage

The primary use for the term extractor is as a JRuby library. There is a command line script wrapping it, but it currently only supports very basic use and isn't really practical because of a long startup time (this is more to do with loading models than Java startup). 

Use of the library is very simple:

    jirb -rubygems -rterm-extractor
    irb(main):001:0> extractor = TermExtractor.new
    irb(main):002:0>  puts extractor.extract_terms_from_text("Scala is a multi-paradigm programming language designed to integrate features of object-orientedd programming and functional programming.") 
    Scala
    multi-paradigm programming language
    features
    irb(main):003:0> p extractor.extract_terms_from_text("Scala is a multi-paradigm programming language designed to integrate features of object-orientedd programming and functional programming.")     
    [#<Term:0xd36ff3 @to_s="Scala", @pos="NNP", @sentence=0>, #<Term:0x15af049 @to_s="multi-paradigm programming language", @pos="JJ-NN-NN", @sentence=0>, #<Term:0x1555185 @to_s="features", @pos="NNS", @sentence=0>]
    irb(main):004:0> terms = extractor.extract_terms_from_text("Scala is a multi-paradigm programming language designed to integrate features of object-orientedd programming and functional programming.") 
    irb(main):006:0> p terms[0]
    #<Term:0x1c958af @to_s="Scala", @pos="NNP", @sentence=0>
    irb(main):007:0> puts terms[0].pos
    NNP
    irb(main):008:0> puts terms[0].sentence
    0
    irb(main):009:0> puts terms[0].to_s    
    Scala

You create a term extractor. You pass it text with extract_terms_from_text and it returns an array of Term objects. You'll probably most be interested in these to convert them straight to strings, where they correspond to the desired snippets of text from the document, but they also provide some additional information. Currently they provide information about parts of speech and which sentence in the text they occur in. More information may be added later. 

## Copyright

Copyright (c) 2009 Trampoline Systems. See LICENSE for details.
