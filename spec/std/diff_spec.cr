require "diff"
require "spec"

describe Diff do
  describe "diff" do
    it { Diff.diff([1, 2], [1, 2]).should eq([] of Diff::Delta) }
    it { Diff.diff([1, 2, 3], [1, 3]).should eq([Diff::Delta.new(1...2, 1...1)]) }
    it { Diff.diff([1, 3], [1, 2, 3]).should eq([Diff::Delta.new(1...1, 1...2)]) }
    it { Diff.diff([1, 2, 3], [1, 3, 4]).should eq([Diff::Delta.new(1...2, 1...1), Diff::Delta.new(3...3, 2...3)]) }
  end

  describe "unified_diff" do
    it "shows a patch as unified diff format" do
      obtained = <<-OBTAINED
        This part of the
        document has stayed the
        same from version to
        version.  It shouldn't
        be shown if it doesn't
        change.  Otherwise, that
        would not be helping to
        compress the size of the
        changes.

        This paragraph contains
        text that is outdated.
        It will be deleted in the
        near future.

        It is important to spell
        check this dokument. On
        the other hand, a
        misspelled word isn't
        the end of the world.
        Nothing in the rest of
        this paragraph needs to
        be changed. Things can
        be added after it.
        OBTAINED
      expected = <<-EXPECTED
        This is an important
        notice! It should
        therefore be located at
        the beginning of this
        document!

        This part of the
        document has stayed the
        same from version to
        version.  It shouldn't
        be shown if it doesn't
        change.  Otherwise, that
        would not be helping to
        compress anything.

        It is important to spell
        check this document. On
        the other hand, a
        misspelled word isn't
        the end of the world.
        Nothing in the rest of
        this paragraph needs to
        be changed. Things can
        be added after it.

        This paragraph contains
        important new additions
        to this document.
        EXPECTED

      Diff.unified_diff(obtained, expected).should eq(<<-PATCH)
        @@ -1,3 +1,9 @@
        +This is an important
        +notice! It should
        +therefore be located at
        +the beginning of this
        +document!
        +
         This part of the
         document has stayed the
         same from version to
        @@ -5,16 +11,10 @@
         be shown if it doesn't
         change.  Otherwise, that
         would not be helping to
        +compress anything.
        -compress the size of the
        -changes.
        #{" "}
        -This paragraph contains
        -text that is outdated.
        -It will be deleted in the
        -near future.
        -
         It is important to spell
        +check this document. On
        -check this dokument. On
         the other hand, a
         misspelled word isn't
         the end of the world.
        @@ -22,3 +22,7 @@
         this paragraph needs to
         be changed. Things can
         be added after it.
        +
        +This paragraph contains
        +important new additions
        +to this document.

        PATCH
    end
  end
end
