# The Trampoline Systems term extractor

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

Currently only english is supported. There are plans 

## Copyright

Copyright (c) 2009 Trampoline Systems. See LICENSE for details.
