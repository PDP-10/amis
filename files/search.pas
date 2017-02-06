(* AMIS search module *)	(* -*-Pascal-*- *)

(****************************************************************************)
(*									    *)
(*  Copyright (C) 1980, 1981, 1982, 1983, 1984, 1985, 1986, 1987 by	    *)
(*  Stacken, Royal Institute Of Technology, Stockholm, Sweden.		    *)
(*  All rights reserved.						    *)
(* 									    *)
(*  This software is furnished under a license and may be used and copied   *)
(*  only in  accordance with  the  terms  of  such  license  and with the   *)
(*  inclusion of the above copyright notice. This software or  any  other   *)
(*  copies thereof may not be provided or otherwise made available to any   *)
(*  other person.  No title to and ownership of  the  software is  hereby   *)
(*  transferred.							    *)
(* 									    *)
(*  The information in this software is  subject to change without notice   *)
(*  and should not be construed as a commitment by Stacken.		    *)
(*									    *)
(*  Stacken assumes no responsibility for the use or reliability of its     *)
(*  software on equipment which is not supported by Stacken.                *)
(* 									    *)
(****************************************************************************)

(*$E+,T-*)			(* Compiler directives. *)

module Search;

const (* Common constant declarations for all AMIS modules. 1981-07-26 / JMR *)
  CtrlAtSign = 0;	    CtrlA = 1;		      CtrlB = 2;
  CtrlC = 3;		    CtrlD = 4;		      CtrlE = 5;
  CtrlF = 6;		    CtrlG = 7;		      CtrlH = 8;
  CtrlI = 9;		    CtrlJ = 10;		      CtrlK = 11;
  CtrlL = 12;		    CtrlM = 13;		      CtrlN = 14;
  CtrlO = 15;		    CtrlP = 16;		      CtrlQ = 17;
  CtrlR = 18;		    CtrlS = 19;		      CtrlT = 20;
  CtrlU = 21;		    CtrlV = 22;		      CtrlW = 23;
  CtrlX = 24;		    CtrlY = 25;		      CtrlZ = 26;
  CtrlLeftBracket = 27;     CtrlBackSlash = 28;	      CtrlRightBracket = 29;
  CtrlUpArrow = 30;	    CtrlUnderScore = 31;      RubOut = 127;

  Null = CtrlAtSign;	    Bell = CtrlG;	      BackSpace = CtrlH;
  HorizontalTab = CtrlI;    LineFeed = CtrlJ;	      FormFeed = CtrlL;
  CarriageReturn = CtrlM;   Escape = CtrlLeftBracket;

  HelpChar = CtrlUnderscore; (* Gives you help almost everywhere in AMIS.    *)

  StrSize = 40; (* Length of fixed length PACKED ARRAY OF CHAR strings.	     *)

type (* Common type declarations for all AMIS modules. 1981-07-26 / JMR      *)
  string = packed array [1 .. StrSize] of char; (* Fixed length string.      *)
  bufpos = integer; (* *** SYSTEM DEPENDENT *** Position in the buffer.      *)

var
  OldStr	: string;	(* Contains the last search string. *)
  OldLen	: integer;	(* Holds significant length of string. *)

(* External procedures and functions in alphabetical order. *)

function BGetChar(i : bufpos) : char; external;
function BufSearch(Str : string; Len, RepeatCount : integer; HowFar : bufpos) :
  boolean; external;
procedure Bug(Str : string); external;
procedure CommandLoop(RecursiveName : string); external;
procedure Delete(Len : bufpos); external;
function Delim(C : char) : boolean; external;
procedure EchoArrow(C : char); external;
procedure EchoClear; external;
procedure EchoDec(Number : integer); external;
procedure EchoString(Str : string); external;
procedure EchoUpdate; external;
procedure EOLString(var Str : string; var Len : integer); external;
procedure Error(Str : string); external;
function GetChar(Dot : bufpos) : char; external;
function GetDot : bufpos; external;
function GetLine(Lines : integer) : bufpos; external;
function GetMark(Pop : boolean) : bufpos; external;
function GetNull(Dot : bufpos) : char; external;
function GetSize : bufpos; external;
procedure Insert(C : char); external;
function KbdStop : boolean; external;
function Letter(C : char) : boolean; external;
function DownCase(C : char) : char; external;
function MetaBit : boolean; external;
procedure ModeClear; external;
procedure ModeString(Str : string); external;
procedure OvWLine; external;
procedure OvWString(Str : string); external;
function QReadC : char; external;
function ReadC : char; external;
procedure ReadLine(Prompt : string; var Str : string; var Length : integer);
  external;
procedure ReMap(var c: char; searching: boolean); external;
procedure ReRead; external;
procedure SetDot(NewDot : bufpos); external;
procedure SetMark(NewMark : bufpos); external;
procedure TrmBeep; external;
procedure TtyWrite(c: char); external;
function UpCase(C : char) : char; external;
procedure WinOverWrite(ch : char); external;
procedure WinPos(row : integer); external;
procedure WinRefresh; external;
procedure WinUpdate; external;

(*---------------------------------------------------------------------------*)
(* Initialization procedure. Should be called at start of program execution. *)

(*@VMS: [global] *)
procedure SeaInit(Total: boolean);
begin
  if Total
  then OldLen := 0
end;

(*---------------------------------------------------------------------------*)
(* IncrementalSearch implements the AMIS functions ^R Incremental Search, ^R *)
(* Reverse Search and ^R String Search. Incremental should be true for ^R    *)
(* Incremental Search and ^R Reverse Search and false for ^R String Search.  *)
(* SearchArg is the numeric argument given to the command for ^R Incremental *)
(* Search and ^R String Search, and the negative of the numeric argument for *)
(* ^R Reverse Search.							     *)

(*@VMS: [global] *)
procedure IncrementalSearch(Incremental : boolean; SearchArg : integer);

type
  refcontext = ^context;
  context = packed record
    Previous : refcontext;
    CSuccess : boolean;
    CSearchLen : 0..StrSize;
    CSearchArg : integer;
    CBeginDot, CDot : bufpos
  end;

var
  SearchStr, ReturnStr : string;
  SearchLen, ReturnLen, ReturnPos : integer;
  BeginDot : bufpos;
  CurrentContext : refcontext;
  BVoid, Success, More : boolean;
  C : char;

  procedure Search;
  var
    TopLine : boolean;
    JumpBefore : (JumpToBeginning, DontJump, JumpToEnd);
    ReturnPos : integer;

    procedure GiveHelp;
    begin
      OvWString('You are typing a search string.         '); OvWLine;
      OvWString('You can rub out, or cancel with one or  ');
      OvWString('two C-G''s.                              '); OvWLine;
      OvWString('C-U cancels the search string.  Rubout  ');
      OvWString('rubs out one character.                 '); OvWLine;
      OvWString('C-R reverses the direction of the       ');
      OvWString('search.                                 '); OvWLine;
      OvWString('C-B starts searching from the beginning ');
      OvWString('of buffer, C-E starts at the end.       '); OvWLine;
      OvWString('C-F positions window so search object is');
      OvWString('displayed near top.                     '); OvWLine;
      OvWString('C-S searches, and returns to read in    ');
      OvWString('loop.  Escape searches and exits.       '); OvWLine;
      OvWString('C-Q quotes control characters to search ');
      OvWString('for them.                               ')
    end;

    function DotSearch : boolean;
    var
      OldDot : bufpos;
      Success : boolean;
    begin
      EchoUpdate;
      if JumpBefore = DontJump
      then begin
	OldDot := GetDot;
	if SearchArg < 0
	then SetDot(OldDot + SearchLen)
      end
      else begin
	if JumpBefore = JumpToBeginning
	then OldDot := 0
	else oldDot := GetSize;
	SetDot(OldDot)
      end (* if *);
      if SearchLen = 0
      then Success := BufSearch(OldStr, OldLen, SearchArg, 0)
      else begin
	Success := BufSearch(SearchStr, SearchLen, SearchArg, 0);
	OldStr := SearchStr;
	OldLen := SearchLen
      end (* if *);
      if Success
      then begin
	if SearchArg < 0
	then SetDot(GetDot - SearchLen);
	if TopLine
	then WinPos(2);
	DotSearch := true
      end
      else begin
	SetDot(OldDot);
	EchoString('FAIL                                    ');
	BVoid := KbdStop;
	DotSearch := false
      end (* if *)
    end (* DotSearch *);

    procedure RePaint;
    var
      Pos : integer;
    begin (* RePaint *)
      EchoClear;
      if JumpBefore = JumpToBeginning
      then EchoString('BJ                                      ')
      else
      if JumpBefore = JumpToEnd
      then EchoString('EJ                                      ');
      if TopLine
      then EchoString('Top Line                                ');
      if SearchArg < 0
      then EchoString('Reverse                                 ');
      EchoString('Search:                                 ');
      for Pos := 1 to SearchLen
      do EchoArrow(SearchStr[Pos])
    end (* RePaint *);

  begin (* Search *)
    TopLine := false;
    JumpBefore := DontJump;
    More := true;
    while More
    do begin
      RePaint;
      WinUpdate;
      C := ReadC;
      ReMap(c, true);
      if C = Chr(HelpChar)	(* C-_ => Display help message.		     *)
      then begin
	GiveHelp
      end
      else
      if C = Chr(CtrlB)		(* C-B => Search forward from beginning.     *)
      then begin
	JumpBefore := JumpToBeginning;
	if SearchArg < 0
	then SearchArg := - SearchArg
      end
      else
      if C = Chr(CtrlE)		(* C-E => Search backward from end.	     *)
      then begin
	JumpBefore := JumpToEnd;
	if SearchArg > 0
	then SearchArg := - SearchArg
      end
      else
      if C = Chr(CtrlF)		(* C-F => Position match near top of screen. *)
      then begin
	TopLine := true
      end
      else
      if C = Chr(CtrlR)		(* C-R => Reverse direction of search.	     *)
      then begin
	if SearchArg > 0
	then SearchArg := - 1
	else SearchArg := 1
      end
      else
      if C = Chr(CtrlS)		(* C-S => Search and return to read in loop. *)
      then begin
	EchoString('^S                                      ');
	More := DotSearch
      end
      else
      if C = Chr(Escape)	(* Escape => Search and exit.		     *)
      then begin
	EchoString('$                                       ');
	BVoid := DotSearch;
	More := false
      end
      else
      if C = Chr(RubOut)	(* Rubout => Rub out one character.	     *)
      then begin
	if SearchLen > 0
	then SearchLen := SearchLen - 1
	else TrmBeep
      end
      else
      if C = Chr(CtrlU)		(* C-U => Rub out the search string.	     *)
      then begin
	SearchLen := 0
      end
      else
      if C = Chr(CarriageReturn)(* Return => Insert end of line sequency into*)
      then begin		(* search string.			     *)
	if SearchLen + ReturnLen > StrSize
	then TrmBeep
	else begin
	  for ReturnPos := 1 to ReturnLen
	  do SearchStr[SearchLen + ReturnPos] := ReturnStr[ReturnPos];
	  SearchLen := SearchLen + ReturnLen
	end
      end
      else begin		(* Other character => Insert it into string. *)
	if C = Chr(CtrlQ)	(* C-Q => Insert next character into string. *)
	then begin
	  C := QReadC;
	end (* if *);
	if SearchLen + 1 > StrSize
	then TrmBeep
	else begin
	  SearchStr[SearchLen + 1] := C;
	  SearchLen := SearchLen + 1
	end
      end (* if *)
    end (* while *)
  end (* Search *);

  procedure GiveHelp;
  begin (* GiveHelp *)
    OvWString('You are typing a search string.         '); OvWLine;
    OvWString('You can rub out, or cancel with one or  ');
    OvWString('two C-G''s.                              '); OvWLine;
    OvWString('C-R and C-S change direction or repeat  ');
    OvWString('the search,                             '); OvWLine;
    OvWString('C-R backward and C-S forward.  Escape   ');
    OvWString('exits.                                  '); OvWLine;
    OvWString('C-Q quotes control characters to search ');
    OvWString('for them.                               ')
  end (* GiveHelp *);

  procedure PopContext;
  var
    OldContext : refcontext;
  begin
    if CurrentContext = nil
    then Bug('PopContext: CurrentContext = nil! /JMR  ');
    OldContext := CurrentContext;
    CurrentContext := CurrentContext^.Previous;
    Dispose(OldContext)
  end;

  procedure RestoreContext;
  begin (* RestoreContext *)
    if CurrentContext = nil
    then Bug('RestoreContext: CurrentContext = nil! /J');
    with CurrentContext^
    do begin
      Success := Csuccess;
      SearchLen := CSearchLen;
      SearchArg := CSearchArg;
      BeginDot :=CBeginDot;
      SetDot(CDot)
    end (* with *);
    PopContext
  end (* RestoreContext *);

  procedure SaveContext;
  var
    NewContext : refcontext;
  begin (* SaveContext *)
    New(NewContext);
    with NewContext^
    do begin
      Previous := CurrentContext;
      CSuccess := Success;
      CSearchLen := SearchLen;
      CSearchArg := SearchArg;
      CBeginDot := BeginDot;
      CDot := GetDot
    end (* with *);
    CurrentContext := NewContext
  end (* SaveContext *);

  procedure RePaint;
  var
    Pos : integer;
  begin (* RePaint *)
    EchoClear;
    if not Success
    then EchoString('Failing                                 ');
    if SearchArg < 0
    then EchoString('Reverse                                 ');
    EchoString('I-Search:                               ');
    for Pos := 1 to SearchLen
    do EchoArrow(SearchStr[Pos])
  end (* RePaint *);

  function DotSearch(StartDot : bufpos) : boolean;
  var
    OldDot : bufpos;
  begin (* DotSearch *)
    EchoUpdate;
    OldDot := getdot;
    SetDot(StartDot);
    if BufSearch(SearchStr, SearchLen, SearchArg, 0)
    then begin
      DotSearch := true;
      if SearchArg < 0
      then SetDot(GetDot - SearchLen)
    end
    else begin
      DotSearch:= false;
      BVoid := KbdStop;
      SetDot(OldDot)
    end
  end (* DotSearch *);

begin (* IncrementalSearch *)
  if SearchArg = 0
  then error('NYI? 0 Argument Is Not Yet Implemented  ');
  SearchLen := 0;
  EOLString(ReturnStr, ReturnLen);
  if Incremental
  then begin
    ReturnPos := 0;
    CurrentContext := nil;
    Success := true;
    BeginDot := GetDot;
    More := true;
    while More
    do begin
      RePaint;
      WinUpdate;
      if ReturnPos = 0
      then begin
        C := QReadC;
	ReMap(c, true);
      end (* if *);
      if (ReturnPos > 0)	(* End of line sequency *)
      or (not MetaBit) and	(* Or kind of printing char *)
	 (c in [chr(HorizontalTab), chr(LineFeed), chr(CtrlQ),
		' '..'~' (*@VMS: , chr(160)..chr(255) *)])
      then begin		(* Insert it into string and search. *)
	SaveContext;
	if ReturnPos > 0	(* End of line sequency => Insert next	     *)
	then begin		(* character from end of line sequency.	     *)
	  C := ReturnStr[ReturnPos];
	  ReturnPos := ReturnPos + 1;
	  if ReturnPos > ReturnLen
	  then ReturnPos := 0
	end
	else
	if C = Chr(CtrlQ)	(* C-Q => Read another character, and use    *)
	then begin		(* that character instead.		     *)
	  C := QReadC;
	end (* if *);
	if SearchLen = StrSize
	then TrmBeep
	else begin
	  SearchLen := SearchLen + 1;
	  SearchStr[SearchLen] := C;
	  if Success
	  then begin
	    if SearchArg > 0
	    then Success := DotSearch(GetDot - SearchLen + 1)
	    else
	    if SearchLen = 1
	    then Success := DotSearch(GetDot)
	    else
	    if BeginDot > GetDot + SearchLen
	    then Success := DotSearch(GetDot + SearchLen)
	    else Success := DotSearch(BeginDot)
	  end
	  else TrmBeep;
	end (* if *)
      end
      else
      if (C = Chr(HelpChar)) and (* C-_ => Display help message.	     *)
         (not MetaBit)
      then begin
        GiveHelp
      end
      else
      if (C = Chr(CarriageReturn)) and (* Return => Insert end of *)
         (not MetaBit)		(* line sequency into *)
      then begin		(* search string, instead of the characters  *)
        ReturnPos := 1		(* typed in, next time.			     *)
      end
      else
      if (C = Chr(RubOut)) and	(* Rubout => Rub out one character in the    *)
         (not MetaBit)
      then begin		(* search string, or one C-R or C-S command. *)
	if CurrentContext = nil
	then TrmBeep
	else RestoreContext
      end
      else
      if (C = Chr(CtrlG)) and	(* C-G => Rub out untill success, if failing,*)
         (not MetaBit)
      then begin		(* rub out all the way back, if successfull. *)
	if Success
	then begin
	  if CurrentContext <> nil
	  then begin
 	    while CurrentContext^.Previous <> nil
	    do PopContext;
	    RestoreContext
	  end (* if *);
	  More := false
	end
	else begin
	  while not Success
	  do RestoreContext
	end (* if *)
      end
      else
      if (C = Chr(CtrlR)) and	(* C-R => Search backward, recalling the old *)
          (not MetaBit)
      then begin		(* search string, if the current is empty.   *)
	SaveContext;
	if SearchLen = 0
	then begin
	  SearchArg := - 1;
	  SearchStr := OldStr;
	  SearchLen := OldLen;
	  RePaint;
	  Success := DotSearch(GetDot)
	end
	else
	if SearchArg < 0
	then begin
	  if Success
	  then Success := DotSearch(GetDot + SearchLen - 1)
	  else TrmBeep
	end
	else begin
	  Success := true;
	  SearchArg := - 1;
	  RePaint;
	  Success := DotSearch(GetDot)
	end (* if *)
      end
      else
      if (C = Chr(CtrlS)) and	(* C-S => Search forward, recalling the old  *)
         (not MetaBit)
      then begin		(* search string, if the current is empty.   *)
	SaveContext;
	if SearchLen = 0
	then begin
	  SearchArg := 1;
	  SearchStr := OldStr;
	  SearchLen := OldLen;
	  RePaint;
	  Success := DotSearch(GetDot)
	end
	else
	if SearchArg > 0
	then begin
	  if Success
	  then Success := DotSearch(GetDot - SearchLen + 1)
	  else TrmBeep
	end
	else begin
	  Success := true;
	  SearchArg := 1;
	  RePaint;
	  Success := DotSearch(GetDot)
	end (* if *)
      end
      else
      if (C = Chr(Escape)) and (not MetaBit) and
         (SearchLen = 0)	(* Escape AND Empty search     *)
      then begin		(* string => Enter ^R String Search.	     *)
        Search
      end
      else begin		(* Other character => Exit, and remember the *)
	OldStr := SearchStr;	(* search string. Reread the character unless*)
	OldLen := SearchLen;	(* it is Escape.			     *)
	EchoString('$                                       ');
        if (C <> Chr(Escape)) or MetaBit
	then ReRead;
	More := false
      end (* if *)
    end (* while *);
    while CurrentContext <> nil
    do PopContext
  end
  else Search
end (* IncrementalSearch *);

(*---------------------------------------------------------------------------*)
(* QueryReplace implements the AMIS functions Query Replace and Replace	     *)
(* String. Query should be true for Query Replace and false for Replace	     *)
(* String. Delimitered should be true if a numeric argument was given to     *)
(* Query Replace or Replace String. The routine prompts with 'Replace:' and  *)
(* reads the search string from the terminal. Thereafter it prompts with     *)
(* 'with:' and reads the replacement string. The last part of the routine    *)
(* is a loop, in which the replacement is done.				     *)

(*@VMS: [global] *)
procedure QueryReplace(Query, Delimitered : boolean);
var
  ModeName : string;
  SearchStr, ReplaceStr : string;
  SearchLen, ReplaceLen, SearchFirstLetter, ReplaceFirstLetter : integer;
  PreserveCase, DontSearch, DontReplace, More : boolean;
  C : char;

  procedure GiveHelp;
  begin (* GiveHelp *)
    OvWString('Space => replace, Rubout => don''t, Comma');
    OvWString('=> replace and show,                    ');
    OvWLine;
    OvWString('Period replaces once and exits, !       ');
    OvWString('replaces all the rest,                  ');
    OvWLine;
    OvWString('C-R enters editor recursively, C-W does ');
    OvWString('so after killing FOO,                   ');
    OvWLine;
    OvWString('^ returns to previous locus, ? gets     ');
    OvWString('help, C-L redisplays,                   ');
    OvWLine;
    OvWString('Escape exits, anything else exits and   ');
    OvWString('is reread.                              ');
    OvWLine;
    OvWLine;
    OvWString('Type a space to see buffer again.       ')
  end (* GiveHelp *);  

  procedure CheckCase(Str : string; Len : integer);
  var
    Pos : integer;
    FoundLower, FoundUpper : boolean;
    C : char;
  begin (* CheckCase *)
    if PreserveCase  
    then begin
      Pos := 1;
      FoundLower := false;
      FoundUpper := false;
      while (Pos <= Len) and not FoundUpper
      do begin
	C := Str[Pos];
	if C <> UpCase(C)
	then FoundLower := true
	else
	if C <> DownCase(C)
	then FoundUpper := true;
	Pos := Pos + 1
      end (* while *);
      PreserveCase := FoundLower and not FoundUpper
    end (* if *)
  end (* CheckCase *);

  function FindFirstLetter(Str : string; Len : integer) : integer;
  var
    Pos : integer;
    FoundLetter : boolean;
  begin (* FindFirstLetter *)
    Pos := 1;
    FoundLetter := false;
    while (Pos <= Len) and not FoundLetter
    do begin
      FoundLetter := Letter(Str[Pos]);
      Pos := Pos + 1
    end (* while *);
    if not FoundLetter
    then Bug('FindFirstLetter: None found! /JMR       ');
    FindFirstLetter := Pos - 1
  end (* FindFirstLetter *);

  function DotSearch : boolean;
  var
    More : boolean;
    OldDot : bufpos;
  begin (* DotSearch *)
    if Delimitered
    then begin
      OldDot := GetDot;
      More := true;
      while More
      do begin
	if not BufSearch(SearchStr, SearchLen, 1, 0)
	then begin
	  SetDot(OldDot);
	  DotSearch := false;
	  More := false
	end
	else
	if Delim(GetNull(GetDot - SearchLen - 1))
	and Delim(GetNull(GetDot))
	then begin
	  DotSearch := true;
	  More := false
	end (* if *)
      end (* while *)
    end
    else DotSearch := BufSearch(SearchStr, SearchLen, 1, 0);
  end (* DotSearch *);

  procedure Replace;
  var
    Pos : integer;
    FirstUpper, RestUpper, FoundLetter : boolean;
    Dot, Size : bufpos;
    C : char;
  begin (* Replace *)
    if PreserveCase
    then begin
      FirstUpper := false;
      RestUpper := false;
      Dot := GetDot - SearchLen + SearchFirstLetter - 1;
      C := GetChar(Dot);
      if C <> DownCase(C)
      then begin
	FirstUpper := true;
	RestUpper := true;
	Dot := Dot + 1;
	Size := GetSize;
	FoundLetter := false;
	while (Dot < Size) and not FoundLetter
	do begin
	  C := GetChar(Dot);
	  FoundLetter := Letter(C);
	  Dot := Dot + 1
	end (* while *);
	if FoundLetter
	then RestUpper := C <> DownCase(C)
      end (* if *);
      Delete (- SearchLen);
      for Pos := 1 to ReplaceFirstLetter
      do
      if FirstUpper
      then Insert(UpCase(ReplaceStr[Pos]))
      else Insert(ReplaceStr[Pos]);
      for Pos := ReplaceFirstLetter + 1 to ReplaceLen
      do
      if RestUpper
      then Insert(UpCase(ReplaceStr[Pos]))
      else Insert(ReplaceStr[Pos])
    end
    else begin
      Delete(- SearchLen);
      for Pos := 1 to ReplaceLen
      do Insert(ReplaceStr[Pos])
    end (* if *)
  end (* Replace *);

  procedure RePaint;
  var
    Pos : integer;
  begin (* RePaint *)
    ModeClear;
    ModeString(ModeName);
    EchoClear;
    EchoString('Replace:                                ');
    for Pos := 1 to SearchLen
    do EchoArrow(SearchStr[Pos]);
    EchoString(' with:                                  ');
    for Pos := 1 to ReplaceLen
    do EchoArrow(ReplaceStr[Pos])
  end (* RePaint *);

begin (* QueryReplace *)
  ModeName := 'Query Replace.                          ';
  EchoClear;
  ReadLine('Replace:                                ', SearchStr, SearchLen);
  ReadLine(' with:                                  ', ReplaceStr, ReplaceLen);
  PreserveCase := true;
  CheckCase(SearchStr, SearchLen);
  CheckCase(ReplaceStr, ReplaceLen);
  if PreserveCase
  then begin
    SearchFirstLetter := FindFirstLetter(SearchStr, SearchLen);
    ReplaceFirstLetter := FindFirstLetter(ReplaceStr, ReplaceLen)
  end (* if *);
  if Query
  then begin
    ModeClear;
    ModeString(ModeName)
  end
  else begin
    EchoClear;
    EchoUpdate
  end;
  DontSearch := false;
  DontReplace := false;
  More := true;
  while More
  do begin
    if not DontSearch
    then begin
      SetMark(GetDot);
      More := DotSearch
    end (* if *);
    if More
    then
    if Query
    then begin
      WinUpdate;
      C := QReadC;
      if ((C = Chr(HelpChar)) or (C = '?')) and
         (not MetaBit)		(* C-_ and ? => Show help message. *)
      then begin
	GiveHelp;
	DontSearch := true
      end
      else
      if (C = ' ') and (not MetaBit) (* Space => Replace, and continue.	     *)
      then begin
        if not DontReplace
        then Replace;
	DontSearch := false;
	DontReplace := false
      end
      else
      if (C = Chr(Rubout)) and (not MetaBit) (* Rubout => Don't replace, *)
				(* but continue. *)
      then begin
	DontSearch := false;
	DontReplace := false
      end
      else
      if (C = ',') and (not MetaBit) (* Comma => Replace, and stay there. *)
      then begin
        if not DontReplace
        then Replace;
	DontSearch := true;
	DontReplace := true
      end
      else
      if (C = '.') and (not MetaBit) (* Period => Replace, and exit.	     *)
      then begin
        if not DontReplace
        then Replace;
	More := false
      end
      else
      if (C = '!') and (not MetaBit) (* Exclamation point => Replace, *)
      then begin		(* and continue without asking *)
        EchoClear;
	EchoUpdate;
	if not DontReplace
        then Replace;
	DontSearch := false;
	DontReplace := false;
	Query := false
      end
      else
      if ((C = Chr(CtrlR)) or (C = Chr(CtrlW))) and (not MetaBit)
				(* C-R and C-W => Enter	recursive edit level *)
      then begin
	if (C = Chr(CtrlW)) and not DontReplace
	then Delete(- SearchLen);(* C-W => delete match before.		     *)
        CommandLoop(ModeName);
	RePaint;
	DontSearch := true;
	DontReplace := true
      end
      else
      if (C = '^') and (not MetaBit) (* ^ => Return to previous match.	     *)
      then begin
	SetDot(GetMark(true));
	DontSearch := true;
	DontReplace := true
      end
      else
      if (C = Chr(CtrlL)) and (not MetaBit) (* C-L => Redisplay window.	    *)
      then begin
	WinRefresh;
	DontSearch := true
      end
      else begin		(* Other character => Exit, and reread the   *)
        if (C <> Chr(Escape)) or (* character, unless it is Escape.	     *)
	   MetaBit
	then ReRead;
	More := false
      end
    end
    else Replace
  end (* while *);
  if Query
  then EchoClear
end (* QueryReplace *);

(*---------------------------------------------------------------------------*)
(* HowMany implements the AMIS function How Many. It prompts with 'Pattern:' *)
(* and reads the pattern string from the terminal. Then it counts the number *)
(* of occurences of the pattern string, after point.			     *)

(*@VMS: [global] *)
procedure HowMany;
var
  SearchStr : string;
  SearchLen, Occurences : integer;
  OldDot : bufpos;
begin (* HowMany *)
  EchoClear;
  OldDot := GetDot;
  ReadLine('Pattern:                                ', SearchStr, SearchLen);
  EchoClear;
  EchoUpdate;
  Occurences := 0;
  while BufSearch(SearchStr, SearchLen, 1, 0)
  do Occurences := Occurences + 1;
  EchoDec(Occurences);
  EchoString(' occurences                             ');
  EchoUpdate;
  SetDot(OldDot)
end (* HowMany *);

(*---------------------------------------------------------------------------*)
(* Occur implements the AMIS function Occur. It prompts with 'Pattern:'      *)
(* and reads the pattern string from the terminal. Then it shows every line, *)
(* after point, that contains the pattern string.                            *)

(*@VMS: [global] *)
procedure Occur;
var
  SearchStr : string;
  SearchLen : integer;
  OldDot, First, Last, P : bufpos;
  Ch : char;
begin (* Occur *)
  EchoClear;
  OldDot := GetDot;
  ReadLine('Pattern:                                ', SearchStr, SearchLen);
  while BufSearch(SearchStr, SearchLen, 1, 0)
  do begin
    First:= GetLine(0); Last:= GetLine(1);
    for P:= First to Last-1 do WinOverWrite(BGetChar(P));
    Setdot(Last);
  end;
  SetDot(OldDot)
end (* Occur *);

(*---------------------------------------------------------------------------*)

(*@TOPS: begin end. *)
(*@VMS: end. *)
