---
title: "The State of C++ with Flex and Bison"
date: 2018-01-13T15:32:00-07:00
draft: false
---

The compilers class I took as an undergraduate at the University of Connecticut is the most challenging yet interesting classes I have ever taken.  The project-driven class gives students hands-on experience with writing a compiler by breaking the large task into smaller subtasks over the course of the semester.  Specifically, students need to write a compiler that translates C--, a simple subset of C, to LLVM IR.  From there, students use the LLVM toolchian to finish compiling C-- to machine code.

To help with the scanner and the parser bits that are essential to any compiler, students use the GNU tools flex and bison.  These are time-tested text-processing programs known for not requiring any additional runtime or build requirements for the code they generate.  In this sense, the code they generate for doing the actual text processing is portable.  Who doesn't like portability?

These text-processing programs are also mature with many years of development behind them... or so I thought once I started using them more.  The many years of development part, sure.  But the mature part?  It depends on what API or interface is being used.  Do you care about reentrancy?  Do you care about C++?  If so, buckle in for an exciting ride!

I wanted to revisit my knowledge of flex and bison with a program I'm developing outside of work.  The goal of the program is to generate the scaffolding for a model before everything is 3D printed and to provide a means for graphically interacting with the result.  The model is given to the program in the form of either a text or binary STL file.  I wanted to see if I could write a parser for a text STL file using flex and bison.

The syntax for a text STL file is very simple.  It's given below:

``` plain
solid name
	facet normal ni nj nk
		outer loop
			vertex v1x v1y v1z
			vertex v2x v2y v2z
			vertex v3x v3y v3z
		endloop
	endfacet
endsolid name
```

I wanted to treat the file as a stream to avoid scanning the file twice (one pass for finding how many facets are in the file and another pass for parsing the facets from the file).  I became interested in the C++ interface for flex and bison because I wanted to use the vector container from the Standard Template Library (STL) to accomplish this.

Previous versions of bison used a union interface which only allows tokens and semantic values to be defined with trivial data types (unless pointers are used).  Bison 3.0 introduced a variant interface which allows complex data types to be used.  Suddenly, tokens and semantic values could be defined as follows:

``` c++
%token <float> FLOAT
%type <std::array<std::array<float, 3>, 4>> facet
```

These are natural definitions that are easy to read and understand.  I figured I would try to get on board with the variant interface in conjunction with the C++ interface for bison.

I began looking through the GNU documentation for guidance on how to use these interfaces with bison.  I found a complete C++ example that I thought would help me to get up and going quickly: https://www.gnu.org/software/bison/manual/html_node/Calc_002b_002b-Parser.html.

After reading through the example, the complexity of what I'm trying to achieve with bison becomes apparent.

Two separate code sections are required for parsing.  One section is for the grammar actions, and one section is for the generated parser code overall.  The following code section is required for grammar actions to use the STL and to have detailed knlowdge about the driver, which orchestrates the parsing from the main program:

``` c++
%code requires {
    #include <array>
    #include <vector>
    class StlTextDriver;
}
```

But the generated parser code also needs detailed knolwedge of the driver, which requires the following code section:

``` c++
%code {
    #include "StlTextDriver.h"
}
```

While I understand that the %code requires section breaks a circular dependency by forward declaring the the driver, the distinction between these two sections seems unnecessray.  It's not realy a big deal at this point, so I brushed this off and kept working on the implementation of the parser.

To keep things simple for the first implementation, I removed location-based tracking with the notion that I would add it later if became important.  When I tried to compile the generated parser code, I received an error about a missing definition of YY_NULLPTR.  This looked like a bug in bison to me.  At this point, a red flag goes up.  To work around it, I decided to define it manually in the scanner in a manner consistent with the C++11 standard:

``` c++
#ifndef YY_NULLPTR
	#define YY_NULLPTR nullptr
#endif
```

Another red flag goes up when I saw that the example recommends defining which version of the skeleton to use for parsing:

``` c++
%require "3.0.4"
```

The C++ interface is starting to look less and less mature, further corroborated when the next red flag goes up.  The example recommends specifying an option to ensure that the parser is using the variant interface correctly:

``` c++
%define parse.assert
```

This seems unnecesary because the variant interface should be used correctly behind the scenes... automatically.

Overlooking these red flags and attributing them to user error, the parser seems pretty straight-forward.  I decided to take a look at what the C++ interface for flex is like.

https://www.gnu.org/software/bison/manual/html_node/Calc_002b_002b-Scanner.html#Calc_002b_002b-Scanner

A close at the example reveals that while the example may be complete, it's not using the C++ interface.  No option is being defined for this scanner to be C++.  It's also not even reentrant as no option is defined for this either.  I didn't notice this at first.  What tipped me off was how the fopen method was being used to open a file for yyin.  This is the C interface for file I/O.  I was expecting something from ifstream or ofstream if this was using the C++ interface.  Knowing that I was using the flex C interface with global variables and meshing it with the bison C++ interface with local variables felt just downright ugly.

I found additional GNU documentation that I thought would help me better understand the C++ interface for flex: https://ftp.gnu.org/old-gnu/Manuals/flex-2.5.4/html_node/flex_19.html

The example looks straight-forward and the C++ interface looks straight-forward to use if I'm just scanning and producing tokens.  I get a FlexLexer class to work with, and I just call lex to advance the stream.  Perfect!  But, I could not find documentatoin on how to bridge this with bison.

I figured to best way to solve this problem would be to open the generated scanner code and begin an archeological dig.  I was immediately greeted with the following message:

``` c++
/* The c++ scanner is a mess. The FlexLexer.h header file relies on the
* following macro. This is required in order to pass the c++-multiple-scanners
* test in the regression suite. We get reports that it breaks inheritance.
* We will address this in a future release of flex, or omit the C++ scanner
* altogether.
*/
```

Hmm... it seems that the C++ scanner is still under active development and needs more work, and could potentially be removed in the future.  Given the release cadence of flex and bison, this isn't going to be for a while.  At this point, I figured this is why the complete C++ example was written the way it was.

Ignoring the uncertain future of the C++ scanner, I wanted to see if I could find other examples that might be able to help me out, given the GNU documentation wasn't getting me very far (which wasn't encouraging).  I found two complete examples of the C++ interface for flex and bison.  These seem to be the only realiable two in existence that have enough explanation around them to justify using them as a reference.

http://www.jonathanbeard.io/tutorials/FlexBisonC++
https://github.com/ezaquarii/bison-flex-cpp-example

The problem with both of these examples is they approach the problem slightly differently.  Sure, I could say that I like jonathanbeard's implemetation better because I can understand it better (because the documentation is better).  But that didn't mean I was necessarily doing it in the best way.

To find a tie-breaker for determining the "best" way, I took a look at what other technical literature has to say about flex and bison.  O'Rielly is a respected technical publisher, and I see many of their books at my workplace on coworker's shelves.  Their book Flex and Bison was published in 2009, which is a little dated.  After reading through a couple of the chapters, red flags go up again about the state of reentrant parsers and scanners, and of the C++ interface:

"Unfortunately, as of the time this book went to press (mid-2009), the code for flex pure scanners and yacc pure scanners is a mess. Bison’s calling sequence for a pure yylex() is different from flex’s, and the way they handle per-instance data is different. It’s possible to paper over the problems in the existing code and persuade pure scanners and parsers to work together, which is what we will do in this chapter, but before doing so, check the latest flex and bison documentation."

"As should be apparent by now, the C++ support in bison is nowhere near as mature as the C support, which is not surprising since it’s about 30 years newer."

It seems not much has changed since 2009... and checking the latest flex and bison documentation like the book recommends has already proven to be a losing battle.

The documentation for the C++ interface for flex and bison is obstensibly lacking, and for this program, while I have written grammar and scanner definitions which have a good chance at working because they appear to be logically correct, I am struggling with the implementation because the documentation is so poor for these tools.

By this point, I have decided to completely drop flex and bison and look for a different solution for constructing the text STL parser.  I am interested in a solution that is designed to seamlessly integrate with C++, that doesn't have awkward code generation bits, and that have matured nicely over the years.  Perhaps such an alternative solution will also allow me to write a binary STL parser.  I don't want to drop a parsing solution altogether and just use regular expressions or manual bit sifting because they are not the easiest to maintain, and they are more error-prone than using tools that guarantee good use.

Nonetheless, all I have to say about flex and bison is, it's been fun.  So long, farewell, auf wiedersehen goodbye!

## References

* https://panthema.net/2007/flex-bison-cpp-example/flex-bison-cpp-example-0.1.4/doxygen-html/
* http://www.hwaci.com/sw/lemon/
