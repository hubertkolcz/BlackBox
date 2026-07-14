(* Build TheBlackBoxFramework.nb from the .wl computational-essay sources.
   Headless-safe: parses the (* ::Style:: *) cell grammar of the master file and the three
   section fragments into Cell[] objects, inlines the fragments where the master's Get cell
   sits, assembles a Notebook[] expression, and writes it. Primary path: Export[...,"NB"].
   Fallback (no front end): serialize the Notebook expression with
   ToString[expr, InputForm, CharacterEncoding -> "PrintableASCII"] behind the standard
   notebook header -- a valid, front-end-free .nb. Run:
       wolframscript -file BuildBlackBoxFrameworkNotebook.wl *)
SetDirectory[DirectoryName[$InputFileName]];
root = ParentDirectory[Directory[]];
masterFile = FileNameJoin[{root, "TheBlackBoxFramework.wl"}];
sectionFiles = FileNameJoin[{root, "docs", "essay-src", #}] & /@
   {"essay_sections_1_3.wl", "essay_sections_4_6.wl", "essay_sections_7_10.wl"};
nbFile = FileNameJoin[{root, "TheBlackBoxFramework.nb"}];

markerQ[line_] := Module[{s = StringTrim[line]},
   StringStartsQ[s, "(* ::"] && StringEndsQ[s, ":: *)"]];
markerStyle[line_] := StringTrim@StringTake[StringTrim[line], {6, -6}];
styleMap = <|"Package" -> Null, "Abstract" -> "Text",
   "Title" -> "Title", "Subtitle" -> "Subtitle", "Subsubtitle" -> "Subsubtitle",
   "Section" -> "Section", "Subsection" -> "Subsection", "Subsubsection" -> "Subsubsection",
   "Text" -> "Text", "Item" -> "Item", "ItemNumbered" -> "ItemNumbered",
   "CodeText" -> "CodeText", "Input" -> "Input", "Code" -> "Code", "Output" -> "Output"|>;

stripComment[block_String] := Module[{s = StringTrim[block]},
   If[StringStartsQ[s, "(*"], s = StringDrop[s, 2]];
   If[StringEndsQ[s, "*)"], s = StringDrop[s, -2]];
   StringTrim[s]];

(* When splicing self-contained section fragments under the master's single Title,
   demote each fragment's headings one level so the assembled essay reads as ONE
   document (one Title, fragments as top-level Sections) rather than four stacked
   title pages. Applied only to the fragments; the master keeps its own hierarchy. *)
demoteMap = <|"Title" -> "Section", "Subtitle" -> "Text",
   "Section" -> "Subsection", "Subsection" -> "Subsubsection",
   "Subsubsection" -> "Subsubsection"|>;

parseCells[file_, demote_ : <||>] := Module[
   {lines, cells = {}, i = 1, n, style, buf, content, cellStyle},
   lines = Import[file, "Lines"];
   n = Length[lines];
   While[i <= n,
    If[markerQ[lines[[i]]],
     style = markerStyle[lines[[i]]]; i++;
     buf = {};
     While[i <= n && ! markerQ[lines[[i]]], AppendTo[buf, lines[[i]]]; i++];
     content = StringTrim@StringRiffle[buf, "\n"];
     Which[
      style === "Package" || ! KeyExistsQ[styleMap, style], Null,
      styleMap[style] === "Input" || style === "Code",
        If[content =!= "", AppendTo[cells, Cell[content, "Input"]]],
      True,
        content = stripComment[content];
        cellStyle = Lookup[demote, styleMap[style], styleMap[style]];
        If[content =!= "", AppendTo[cells, Cell[content, cellStyle]]]],
     i++]];
   cells];

masterCells = parseCells[masterFile];
sectionCells = Join @@ (parseCells[#, demoteMap] & /@ sectionFiles);
(* Splice the fragments in where the master's Get-section cell sits. Match the GET
   cell specifically (`Get[FileNameJoin[{frameworkRoot, ...`) -- NOT any cell that
   merely mentions a section filename: the standalone-loader manifest now lists the
   section paths too, so a bare "essay_sections_1_3" match would hit (and delete) the
   frameworkRoot loader instead of the Get cell. *)
getPos = FirstPosition[masterCells,
    Cell[c_String, "Input"] /; StringContainsQ[c, "Get[FileNameJoin[{frameworkRoot"], Missing[]];
assembledCells = If[MissingQ[getPos],
   Join[masterCells, sectionCells],
   Join[Take[masterCells, First[getPos] - 1], sectionCells, Drop[masterCells, First[getPos]]]];

nbExpr = Notebook[assembledCells, StyleDefinitions -> "Default.nb"];

writeFallback[] := Module[{str, stream},
   str = ToString[nbExpr, InputForm, CharacterEncoding -> "PrintableASCII"];
   stream = OpenWrite[nbFile, CharacterEncoding -> "PrintableASCII"];
   WriteString[stream,
    "(* Content-type: application/vnd.wolfram.mathematica *)\n\n",
    "(*** Wolfram Notebook File ***)\n",
    "(* http://www.wolfram.com/nb *)\n\n",
    "(* CreatedBy='TheBlackBoxFramework assembler' *)\n\n"];
   WriteString[stream, str];
   Close[stream];];

exportOK = Quiet@Check[Export[nbFile, nbExpr, "NB"]; True, False];
If[! (exportOK && FileExistsQ[nbFile] && FileByteCount[nbFile] > 2000),
   writeFallback[]; method = "ToString/PrintableASCII fallback",
   method = "Export NB"];

Print["cells (master, sections, assembled): ",
   {Length[masterCells], Length[sectionCells], Length[assembledCells]}];
Print["style census: ", Sort@Tally[assembledCells[[All, 2]]]];
Print["notebook: ", nbFile];
Print["bytes: ", FileByteCount[nbFile], "  method: ", method];
Print["reparse head is Notebook: ",
   MatchQ[Quiet@Check[ToExpression[
       StringDrop[Import[nbFile, "Text"],
        StringLength["(* Content-type: application/vnd.wolfram.mathematica *)"]],
       InputForm, Hold], $Failed], Hold[_Notebook]]];
