# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{term-extractor}
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David R. MacIver"]
  s.date = %q{2009-08-06}
  s.default_executable = %q{terms.rb}
  s.email = %q{david.maciver@gmail.com}
  s.executables = ["terms.rb"]
  s.extra_rdoc_files = [
    "LICENSE",
     "README.markdown"
  ]
  s.files = [
    "LICENSE",
     "README.markdown",
     "Rakefile",
     "VERSION",
     "bin/terms.rb",
     "lib/term-extractor.rb",
     "lib/term-extractor/maxent-2.5.2.jar",
     "lib/term-extractor/nlp.rb",
     "lib/term-extractor/opennlp-tools.jar",
     "lib/term-extractor/snowball.jar",
     "lib/term-extractor/trove.jar",
     "licenses/Maxent",
     "licenses/OpenNLP",
     "licenses/Trove",
     "licenses/snowball.php",
     "models/chunk.bin.gz",
     "models/sd.bin.gz",
     "models/stopwords",
     "models/tag.bin.gz",
     "models/tagdict",
     "models/tok.bin.gz",
     "term-extractor.gemspec",
     "test/examples_spec.rb",
     "test/files/1.email",
     "test/files/juries_seg_8_v1",
     "test/nlp_spec.rb",
     "test/term_extractor_spec.rb"
  ]
  s.homepage = %q{http://github.com/david.maciver@gmail.com/term-extractor}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{A library for extracting useful terms from text}
  s.test_files = [
    "test/term_extractor_spec.rb",
     "test/nlp_spec.rb",
     "test/examples_spec.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
