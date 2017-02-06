(* AMIS Utility functions. *)  (* -*-PASCAL-*- *)

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

(*$E+,T- *)

module Utility;
const
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

  HelpChar = CtrlUnderscore;

  StrSize = 40;

  NoDefault = '                                        ';

type
  string = packed array [1..StrSize] of char;

  bufpos = integer;

(* External procedures from module MAIN. *)

function Letter(C: char): boolean; external;
function Delim(C: char): boolean; external;
function UpCase(C: char): char; external;
function DownCase(C: char): char; external;
function GetMark(Pop: boolean): bufpos; external;
function GetTahString(var Str: string; var Len: integer): boolean; external;
procedure SetMark(Mark: bufpos); external;
procedure Error(Str: string); external;
procedure DoCtlW(var Line: string; var Count: integer); external;
procedure ReMap(var c: char; searching: boolean); external;

(* External procedures from module INPUT. *)

function Check(Seconds: integer): boolean; external;
function ReadC: char; external;
function QReadC: char; external;
procedure EchoClear; external;

(* External procedures from module SCREEN. *)

procedure WinOverWrite(c: char); external;
procedure EchoWrite(c: char); external;
procedure EchoArrow(c: char); external;
procedure EchoString(s: string); external;
procedure EchoEOL; external;
procedure EchoUpdate; external;
procedure EchoPos(Row, Col: integer); external;
procedure EchoWhere(var Row, Col: integer); external;

(* External procedures from module TERM. *)

procedure TrmBeep; external;

(* External procedures from module TTYIO. *)

procedure TTyWrite(C: char); external;
procedure TTyForce; external;
procedure Bug(Str: string); external;

(* External procedures from module DSKIO. *)

function DskRecognition(var Line: string; var Pos: integer): boolean; external;
(*@VMS: procedure VGetFSpec(var FileSpec: string); external; *)

(* External procedures from module BUFFER. *)

procedure Unk2String(var Line: string; var Pos: integer); external;
procedure Insert(C: char); external;
procedure RplaChar(C: char); external;
procedure Delete(HowLong: bufpos); external;
function GetChar(Dot: bufpos): char; external;
function GetNull(Dot: bufpos): char; external;
function GetSize: bufpos; external;
function GetDot: bufpos; external;
procedure SetDot(Dot: bufpos); external;
function GetLine(WhatLine: integer): bufpos; external;
function EndLine: bufpos; external;
function AtEOL(Dot: bufpos; Direction: integer): boolean; external;
function EOLSize: integer; external;
function BufSearch(Str: string; Length, Direction: integer;
		   HowLong: bufpos): boolean; external;

(*---------------------------------------------------------------------------*)
(* PutBase inserts a number into a string. Base may be greater than 10.      *)

(*LOCAL*)
procedure PutBase(var Str: string; Number, StartPos, Width, Base: integer);
var
  Pos: integer;
  BVoid: boolean;

  function BackChr(C: char): boolean;
  begin (* BackChr *)
    if Pos < StartPos then begin
      for Pos := StartPos to StartPos + Width - 1 do Str[Pos] := '*';
      BackChr := false;
    end else begin (* Insert character backwards and return true. *)
      Str[Pos] := C;
      Pos := Pos - 1;
      BackChr := true;
    end;
  end; (* BackChr *)

  function BackBase(Number: integer): boolean;
  var
    Quotient, Remainder: integer;
    C: char;
  begin (* BackBase *)
    Quotient := Number div Base;
    Remainder := Number mod Base;
    if Remainder <= 9
    then C := Chr(Remainder + Ord('0'))
    else C := Chr(Remainder + Ord('A') - 10);
    if BackChr(C) then begin
      if Quotient = 0
      then BackBase := true
      else BackBase := BackBase(Quotient);
    end;
  end; (* BackBase *)

begin (* PutBase *)
  for Pos := StartPos to StartPos + Width - 1 do Str[Pos] := ' ';
  Pos := StartPos + Width - 1;
  if BackBase(Abs(Number))
  then begin
    if Number < 0
    then BVoid := BackChr('-');
  end;
end; (* PutBase *)

(*---------------------------------------------------------------------------*)
(* PutDec inserts a decimal number into a string.			     *)

(*@VMS: [global] *)
procedure PutDec(var Str: string; Number, StartPos, Width: integer);
begin
  PutBase(Str, Number, StartPos, Width, 10);
end;

(*---------------------------------------------------------------------------*)
(* SpaceOrTab returns true if character is a space or a tab.		     *)

(*@VMS: [global] *)
function SpaceorTab(C: char): boolean;
begin
  SpaceorTab := (C = ' ') or (C = Chr(HorizontalTab));
end;

(*---------------------------------------------------------------------------*)
(* StrCompare compares to strings, character by character in upper case, and *)
(* returns < 0, = 0 or > 0, in case the first string is less than, equal to  *)
(* or greater than the second.						     *)

(*@VMS: [global] *)
function StrCompare(Str1, Str2: string): integer;
var
  Pos, Difference: integer;
begin
  Pos := 1;
  repeat
    Difference := Ord(UpCase(Str1[Pos])) - Ord(UpCase(Str2[Pos]));
    Pos := Pos + 1;
  until (Difference <> 0) or (Pos > StrSize);
  StrCompare := Difference;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
function StrLength(var Str: string): integer;
var
  Pos, Len: integer;
begin
  Len := 0;
  for Pos := 1 to StrSize do begin
    if Str[Pos] <> ' '
    then Len := Pos;
  end;
  StrLength := Len;
end;

(*---------------------------------------------------------------------------*)
(* OvWDec writes a decimal number in the window.			     *)

(* ===> SCREEN *)

(*@VMS: [global] *)
procedure OvWDec(Number: integer);
var
  Str: string;
  Pos: integer;
begin
  PutBase(Str, Number, 1, StrSize, 10);
  for Pos := 1 to StrSize do
  if Str[Pos] <> ' '
  then WinOverWrite(Str[Pos]);
end;

(*---------------------------------------------------------------------------*)
(* OvWString writes a string in the window, followed by one space, using the *)
(* overwrite routines.							     *)

 (* ==> SCREEN *)

(*@VMS: [global] *)
procedure OvWString(Str: string);
var
  Pos: integer;
begin
  for Pos := 1 to StrLength(Str)
  do WinOverWrite(Str[Pos]);
  WinOverWrite(' ');
end;

(*---------------------------------------------------------------------------*)
(* OvWLine starts a new overwrite line in the window.			     *)

 (* ==> SCREEN *)

(*@VMS: [global] *)
procedure OvWLine;
begin
  WinOverWrite(Chr(CarriageReturn));
  WinOverWrite(Chr(LineFeed));
end;

(*---------------------------------------------------------------------------*)
(* EchoBase writes a number in the echo area. Called by EchoDec and EchoOct, *)
(* but never by any other routine.					     *)

 (* ==> SCREEN ?? *)

(*LOCAL*)
procedure EchoBase(Number, Base: integer);
var
  Str: string;
  Pos: integer;
begin
  PutBase(Str, Number, 1, StrSize, Base);
  for Pos := 1 to StrSize do
  if Str[Pos] <> ' '
  then EchoWrite(Str[Pos]);
end;

(*---------------------------------------------------------------------------*)
(* EchoDec writes a decimal number in the echo area.			     *)

 (* ==> SCREEN *)

(*@VMS: [global] *)
procedure EchoDec(Number: integer);
begin
  EchoBase(Number, 10);
end;

(*---------------------------------------------------------------------------*)
(* EchoOct writes an octal number in the echo area.			     *)

 (* ==> SCREEN *)

(*@VMS: [global] *)
procedure EchoOct(Number: integer);
begin
  EchoBase(Number, 8);
end;

(*---------------------------------------------------------------------------*)
(* ReadDefault prompts with the prompt and the default and reads in a line   *)
(* from the terminal.							     *)

 (* ==> INPUT ?? *)

(*@VMS: [global] *)
procedure ReadDefault(Prompt, Default: string; var ArgLine: string;
		      var ArgLength: integer; fileflag: boolean);

var
  DefaultLength, Pos, Row, Col, StartCol: integer;
  More: boolean;
  c: char;
  Line: string;			(* Local copies for editing. *)
  Length: integer;

  procedure EchoPrompt;
  var
    PromptLength, PromptPos, DefaultPos: integer;
  begin (* EchoPrompt *)
    if DefaultLength = 0
    then EchoString(Prompt)
    else begin
      PromptLength := StrLength(Prompt);
      for PromptPos := 1 to PromptLength - 1
      do EchoArrow(Prompt[PromptPos]);
      EchoWrite('(');
      for DefaultPos := 1 to DefaultLength
      do EchoArrow(Default[DefaultPos]);
      EchoWrite(')');
      if PromptLength > 0
      then EchoArrow(Prompt[PromptLength]);
      EchoWrite(' ')
    end (* if *)
  end; (* EchoPrompt *)

  procedure RePaint;
  var
    RePaintPos: integer;
  begin (* RePaint *)
    EchoPos(Row, StartCol);
    EchoPrompt;
    for RePaintPos := 1 to Pos - 1
    do EchoArrow(Line[RePaintPos]);
    EchoEOL;
    EchoWhere(Row, Col);
    if Col < StartCol
    then StartCol := 0
  end; (* RePaint *)

begin (* ReadDefault *)
  Pos := 1;
  More := not GetTahString(Line, Length);
  if More then begin		(* No type-ahead, prompt user *)
    DefaultLength := StrLength(Default);
    EchoWhere(Row, StartCol);
    EchoPrompt
  end;
  while More do begin
    if not Check(0) then EchoUpdate;
    C := ReadC;
    ReMap(c, false);
    if C = Chr(HelpChar) then begin
      OvWString('You are entering the argument to a      ');
      OvWString('command.                                ');
      OvWLine;
      OvWString('Terminate it with a Return. Rubout      ');
      OvWString('cancels one character.                  ');
      OvWLine;
      OvWString('C-U cancels the argument. C-G aborts    ');
      OvWString('the command.                            ');
      OvWLine;
      OvWLine;
      OvWString('Now type the argument.                  ')
    end else if C = Chr(CarriageReturn) then begin
      EchoUpdate;
      Length := Pos - 1;
      for Pos := Length + 1 to StrSize
      do Line[Pos] := ' ';
      More := false;
    end else if (C = Chr(Escape)) and FileFlag then begin
      if not DskRecognition(Line, Pos) then TrmBeep;
      Repaint;
    end else if C = Chr(RubOut) then begin
      if Pos > 1 then begin
        Pos := Pos - 1;
	RePaint;
      end
      else TrmBeep
    end else if c = chr(CtrlY) then begin
      Unk2String(Line, Pos);
      RePaint;
    end else if C = Chr(CtrlW) then begin
      Pos := Pos - 1;		(* Sigh... remap for DOCTLW *)
      DoCtlW(Line, Pos);
      Pos := Pos + 1;
      RePaint;
    end else if C = Chr(CtrlU) then begin
      Pos := 1;
      RePaint
    end else if C = Chr(CtrlL) then begin
      EchoClear;
      if not Check(0)
      then EchoUpdate;
      RePaint
    end else begin
      if Pos = StrSize
      then TrmBeep
      else begin
	if C = Chr(CtrlQ) then begin
	  if not Check(0) then EchoUpdate;
	  C := QReadC;
	end;
	Line[Pos] := C;
	Pos := Pos + 1;
	EchoArrow(C);
	EchoWhere(Row, Col);
	if Col < StartCol then StartCol := 0;
      end;
    end; (* if *)
  end; (* while *)
  ArgLine := Line;
  ArgLength := Length;
end; (* ReadDefault *)

(*---------------------------------------------------------------------------*)
(* ReadLine reads a line from the terminal, echoing the characters typed in  *)
(* in the echo area. Normal line editing, C-U and Rubout, is in effect.	     *)

 (* ==> INPUT *)

(*@VMS: [global] *)
procedure ReadLine(Prompt: string; var Line: string; var Length: integer);
begin (* ReadLine *)
  ReadDefault(Prompt, NoDefault, Line, Length, false);
end; (* ReadLine *)

(*---------------------------------------------------------------------------*)
(*  ReadFName reads a file name in the same way as ReadLine does.  The       *)
(*  exception is that ReadFName tries to do file name recognition when the   *)
(*  user types Escape.                                                       *)

 (* ==> INPUT *)

(*@VMS: [global] *)
procedure ReadFName(Prompt: string; var Line: string; var Length: integer);
begin
  ReadDefault(Prompt, NoDefault, Line, Length, true);
end;

(*---------------------------------------------------------------------------*)
(* YesOrNo repeats the '(Y or N)? ' question until the user answers Y or N,  *)
(* and returns true if answer was Y in upper or lower case.		     *)

 (* ==> INPUT *)

(*@VMS: [global] *)
function YesOrNo: boolean;
var
  C: char;
begin
  repeat
    EchoString('(Y or N)?                               ');
    EchoUpdate;
    C := UpCase(ReadC);
  until (C = 'Y') or (C = 'N');
  EchoWrite(C);
  EchoWrite(' ');
  EchoUpdate;
  YesOrNo := C = 'Y';
end;

(*---------------------------------------------------------------------------*)
(* HorPos computes the horizontal position in the buffer, not on the screen. *)

 (* ==> SCREEN *)

(*@VMS: [global] *)
function HorPos: integer;
var
  Pos: integer;
  Dot: bufpos;
  c: char;
begin (* HorPos *)
  Pos := 0;
  for Dot := GetLine(0) to GetDot-1
  do begin
    c := GetChar(Dot);
    if c = Chr(HorizontalTab)
    then Pos := (Pos div 8) * 8 + 8
    else if c = Chr(RubOut)
    then Pos := Pos + 2
    else if c < ' '
    then Pos := Pos + 2
    else Pos := Pos + 1;
  end; (* for *)
  HorPos := Pos;
end; (* HorPos *)

(*---------------------------------------------------------------------------*)
(* ExpTabs expands tabs to spaces forward or backward, depending on argument.*)

(*@VMS: [global] *)
procedure ExpTabs(Direction: integer);
var
  OldDot: bufpos;
  Col, Col1, Col2: integer;
begin
  OldDot := GetDot;
  if (Direction > 0) and (GetNull(OldDot) = Chr(HorizontalTab))
  then begin (* Expand tab after dot to spaces.				     *)
    SetDot(OldDot + 1);
    ExpTabs(- 1);
    SetDot(OldDot)
  end
  else
  if (Direction < 0) and (GetNull(OldDot - 1) = Chr(HorizontalTab))
  then begin (* Expand tab before dot to spaces.			     *)
    Col2 := HorPos;
    Delete(- 1);
    Col1 := HorPos;
    for Col := Col1 to Col2 - 1
    do Insert(' ')
  end; (* if *)
end;

(*---------------------------------------------------------------------------*)
(* DelHorSpace deletes spaces and tabs before or after dot.		     *)

(*@VMS: [global] *)
procedure DelHorSpace(Direction: integer);
begin
  if Direction >= 0 (* Delete spaces and tabs after dot.		     *)
  then
  while SpaceOrTab(GetNull(GetDot))
  do Delete(1);
  if Direction <= 0 (* Delete spaces and tabs before dot.		     *)
  then
  while SpaceOrTab(GetNull(GetDot - 1))
  do Delete(-1);
end;

(*---------------------------------------------------------------------------*)
(* Blank counts the number of characters from dot to the first space or tab  *)
(* after the first non space or tab in the specified direction.		     *)

(*@VMS: [global] *)
function Blank(Direction: integer): integer;
var
  Limit, Dot: bufpos;
begin
  Dot := GetDot;
  if Direction > 0 (* Scan forward.					     *)
  then begin
    Limit := EndLine;
    while SpaceOrTab(GetNull(Dot))
    do Dot := Dot + 1;
    while (Dot < Limit) and not SpaceOrTab(GetNull(Dot))
    do Dot := Dot + 1
  end
  else
  if Direction < 0 (* Scan backward.					     *)
  then begin
    Limit := GetLine(0);
    while SpaceOrTab(GetNull(Dot - 1))
    do Dot := Dot - 1;
    while (Dot > Limit) and not SpaceOrTab(GetNull(Dot - 1))
    do Dot := Dot - 1
  end (* if *);
  Blank := Dot - GetDot
end (* Blank *);

(*---------------------------------------------------------------------------*)
(* BlankLines counts the number of characters from dot to the first nonblank *)
(* line in the specified direction.					     *)

(*@VMS: [global] *)
function BlankLines(Direction: integer; After: boolean): integer;
var
  EOLDot, Dot: bufpos;
  More: boolean;
begin
  Dot := GetDot;
  EOLDot := Dot;
  More := true;
  if Direction > 0 (* Scan forward.					     *)
  then
  while More
  do
  if SpaceOrTab(GetNull(Dot))
  then Dot := Dot + 1
  else
  if AtEOL(Dot, 1)
  then begin
    if After
    then begin
      Dot := Dot + EOLSize;
      EOLDot := Dot
    end
    else begin
      EOLDot := Dot;
      Dot := Dot + EOLSize
    end (* if *)
  end
  else More := false
  else
  if Direction < 0 (* Scan backward.					     *)
  then
  while More
  do
  if SpaceOrTab(GetNull(Dot - 1))
  then Dot := Dot - 1
  else
  if AtEOL(Dot, - 1)
  then begin
    if After
    then begin
      Dot := Dot - EOLSize;
      EOLDot := Dot
    end
    else begin
      EOLDot := Dot;
      Dot := Dot - EOLSize
    end (* if *)
  end
  else More := false;
  BlankLines := EOLDot - GetDot;
end;

(*---------------------------------------------------------------------------*)
(* Chars counts number of characters in the buffer in an implementation with *)
(* a multiple character end of line sequence.				     *)

(*@VMS: [global] *)
function Chars(Distance: integer): integer;
var
  Count, EOLCount: integer;
  Dot: bufpos;
begin (* Chars *)
  EOLCount := EOLSize;
  Dot := GetDot;
  for Count := 1 to Distance (* Scan forward.				     *)
  do
  if AtEOL(Dot, 1)
  then Dot := Dot + EOLCount
  else Dot := Dot + 1;
  for Count := Distance to - 1 (* Scan backward.			     *)
  do
  if AtEOL(Dot, - 1)
  then Dot := Dot - EOLCount
  else Dot := Dot - 1;
  Chars := Dot - GetDot;
end; (* Chars *)

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
function Words(Distance: integer): integer;
var
  Count: integer;
  Dot: bufpos;
begin
  Dot := GetDot;
  for Count := 1 to Distance (* Scan forward.				     *)
  do begin
    while Delim(GetChar(Dot))
    do Dot := Dot + 1;
    while not Delim(GetNull(Dot))
    do Dot := Dot + 1
  end (* for *);
  for Count := Distance to - 1 (* Scan backward.			     *)
  do begin
    while Delim(GetChar(Dot - 1))
    do Dot := Dot - 1;
    while not Delim(GetNull(Dot - 1))
    do Dot := Dot - 1
  end (* for *);
  Words := Dot - GetDot
end (* Words *);

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
function Sentences(Distance: integer): integer;
var
  Count: integer;
  Dot, BeginDot, EndDot: bufpos;

  function SentEnd: boolean;
  var
    C: char;
    More: boolean;
  begin (* SentEnd *)
    if Dot = GetSize (* End of buffer is end of sentence, forward. *)
    then SentEnd := Distance > 0
    else
    if (Dot = 0) and (Distance < 0)
    then begin
      EndDot := Dot;
      More := true;
      while More and (BeginDot > EndDot)
      do
      if SpaceOrTab(GetChar(EndDot))
      then EndDot := EndDot + 1
      else
      if AtEOL(EndDot, 1)
      then EndDot := EndDot + EOLSize
      else More := false;
      if BeginDot > EndDot
      then begin
	Dot := EndDot;
	BeginDot := Dot;
	SentEnd := true
      end
    end
    else begin
      SentEnd := false; (* Assume not end of sentence, initially. *)
      if GetChar(Dot) in ['.', '!', '?']
      then begin
	EndDot := Dot + 1;
	while GetNull(EndDot) in [')', ']', '"', '''']
	do EndDot := EndDot + 1;
	if SpaceOrTab(GetNull(EndDot)) or AtEOL(EndDot, 1) or (EndDot=GetSize)
	then
	if Distance > 0
	then begin
	  Dot := EndDot;
	  SentEnd := true
	end
	else begin
	  More := true;
	  while More and (BeginDot > EndDot)
	  do
	  if SpaceOrTab(GetChar(EndDot))
	  then EndDot := EndDot + 1
	  else
	  if AtEOL(EndDot, 1)
	  then EndDot := EndDot + EOLSize
	  else More := false;
	  if BeginDot > EndDot
	  then begin
	    Dot := EndDot;
	    BeginDot := Dot;
	    SentEnd := true
	  end
	  else Dot := Dot - 1 (* Trick to avoid some searching.		     *)
	end
	else
	if Distance > 0
	then Dot := EndDot - 1 (* Trick to avoid some searching.	     *)
	else Dot := Dot - 1 (* Trick to avoid some unnecessary searching.    *)
      end
    end
  end;

begin (* Sentences *)
  Dot := GetDot;
  BeginDot := Dot; (* Start first search from current position.		     *)
  for Count := 1 to Distance (* Scan forward.				     *)
  do
  while not SentEnd
  do Dot := Dot + 1;
  for Count := Distance to - 1 (* Scan backward.			     *)
  do
  while not SentEnd
  do Dot := Dot - 1;
  Sentences := Dot - GetDot
end (* Sentences *);

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure GetRegion(var First, Last: bufpos);
begin
  First := GetDot;
  Last := GetMark(false);
  if First > Last
  then begin
    First := GetMark(false);
    Last := GetDot
  end;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
PROCEDURE chgcase(argument: integer; firstupper, restupper: Boolean);
VAR p	  : 	bufpos;		(* Current position *)
    stop   :	bufpos;		(* Last position+1 to change case of *)
    first  :	Boolean;	(* Character is first in a word *)
    c,d	   :	char;		(* Scratch *)
BEGIN
  IF argument < 0 THEN		(* Compute boundaries *)
  BEGIN
    stop := getdot;
    setdot(getdot + words(argument))
  END
  ELSE
    stop := getdot + words(argument);
  first := true;
  FOR p := getdot TO stop - 1 DO
  BEGIN
    c := getchar(p);		(* Get a character *)
    IF NOT delim(c) THEN
    BEGIN
      IF first THEN		(* Do the case conversion *)
        IF firstupper THEN
          d := upcase(c)
        ELSE
	  d := DownCase(c)
      ELSE
	IF restupper THEN
	  d := upcase(c)
	ELSE
	  d := DownCase(c);
      IF c <> d THEN BEGIN
        setdot(p);
        rplachar(d)
      END;
      first := false
    END
    ELSE
      first := true
  END;
  setdot(stop)			(* Finally, set dot after the last char *)
END;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
PROCEDURE chgregion(uppercase: boolean);
VAR start,stop	: bufpos;
    p 		: bufpos;
    c,d		: char;
BEGIN
  getregion(start, stop);	(* Get the region boundaries *)
  FOR p := start TO stop-1 DO	(* Loop over the region *)
  BEGIN
    c := getchar(p);		(* Get a character *)
    IF uppercase THEN		(* Change case *)
      d := upcase(c)
    ELSE
      d := DownCase(c);
    IF c <> d THEN BEGIN
      setdot(p);
      rplachar(d)
    END
  END;
  IF start = getmark(false)	(* Reset region boundaries *)
  THEN setdot(stop)
  ELSE setdot(start);
END;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
PROCEDURE countlines(allbuf: boolean);	(* Count # of lines in a page *)
VAR start,stop	: bufpos;
    olddot,i	: bufpos;
    line	: string;
    b4,after	: integer;
BEGIN
  start := 0;
  stop := getsize;		(* Assume whole buffer *)
  olddot := getdot;		(* Save old dot for later use *)
  IF NOT allbuf	THEN		(* NOT looking at all of buffer *)
  BEGIN
    line[1] := chr(12);		(* No, look for ^L *)
    IF bufsearch(line,1,-1,0) THEN	(* Before *)
      start := getdot;
    IF bufsearch(line,1,1,0) THEN	(* and after the dot *)
      stop := getdot - 1
  END;
  b4 := 0;			(* Clear # of lines before dot *)
  setdot(olddot);		(* Restore jumbled dot *)
  i := olddot;			(* Get a copy of the dot *)
  WHILE i > start DO
  BEGIN
    b4 := b4 + 1;		(* Count the lines *)
    i := getline(-1);
    setdot(i)
  END;
  after := 0;			(* Clear # of lines after dot *)
  setdot(olddot);		(* Go to old dot, again *)
  i := olddot;
  WHILE i < stop DO
  BEGIN
    after := after + 1;		(* Count lines *)
    i := getline(1);
    setdot(i)
  END;
  setdot(olddot);		(* Restore dot *)
  echoclear;			(* Clear echo area *)
  IF allbuf
  THEN
    echostring('Buffer:                                 ')
  ELSE
    echostring('Page has                                ');
  echodec(b4+after);		(* Print total # of lines *)
  echostring(' lines                                  ');
  echowrite('(');		(* Then print the rest of the junk *)
  echodec(b4);
  echowrite('+');
  echodec(after);
  echowrite(')');
  echowrite(' ')
END;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
function GetQName: integer;
var c: char;
begin
  c := UpCase(ReadC);
  while c = chr(HelpChar) do begin
    OvWString('You are entering a Q-register name.     ');
    OvWString('Legal Q-register names are the          '); OvWLine;
    OvWString('characters A-Z and 0-9.                 '); OvWLine;
    c := UpCase(ReadC)
  end;
  if c in ['A'..'Z']
  then GetQName := ord('A') - ord(c) - 1
  else if c in ['0'..'9']
  then GetQName := ord('0') - ord(c) - 27
  else error('IQN? Invalid Q-register Name            ');
end;

(*---------------------------------------------------------------------------*)
(* StripSOSNumbers removes nulls, line numbers, page marks and other filth,  *)
(* which the line oriented editor Son Of Stopgap on TOPS-10 leaves behind.   *)

(*@VMS: [global] *)
procedure StripSOSNumbers;
var
  OldDot: bufpos;
  Str: string;

  procedure Strip;
  var
    Dot: bufpos;
  begin
    Dot := GetDot;
    if (GetNull(Dot) in ['0'..'9'])
    and (GetNull(Dot + 1) in ['0'..'9'])
    and (GetNull(Dot + 2) in ['0'..'9'])
    and (GetNull(Dot + 3) in ['0'..'9'])
    and (GetNull(Dot + 4) in ['0'..'9'])
    and (GetNull(Dot + 5) = Chr(HorizontalTab))
    then delete(6)
  end;

begin (* StripSOSNumbers *)
  OldDot := GetDot;

  SetDot(0); (* Remove all nulls from the buffer.			     *)
  Str[1] := Chr(Null);
  while BufSearch(Str, 1, 1, 0)
  do Delete(- 1);

  SetDot(0); (* Remove all page marks from the buffer.			     *)
  Str[1] := ' ';
  Str[2] := ' ';
  Str[3] := ' ';
  Str[4] := ' ';
  Str[5] := ' ';
  Str[6] := Chr(CarriageReturn);
  Str[7] := Chr(FormFeed);
  while BufSearch(Str, 7, 1, 0)
  do begin
    Delete(- 7);
    Insert(Chr(FormFeed));
    Strip;
  end (* while *);

  SetDot(0); (* Remove all strange page merks from the buffer, too.	     *)
  Str[7] := Chr(CarriageReturn);
  Str[8] := Chr(FormFeed);
  while BufSearch(Str, 8, 1, 0)
  do begin
    Delete(- 8);
    Insert(Chr(FormFeed));
    Strip
  end (* while *);

  SetDot(0); (* Finally, remove all line numbers from the buffer.	     *)
  Strip;
  Str[1] := Chr(LineFeed);
  while BufSearch(Str, 1, 1, 0)
  do Strip;

  SetDot(OldDot);
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure GetFSpec(var FileSpec: string; FileNumber: integer);
begin
  case FileNumber of
   (*@TOPS:
    1: FileSpec := 'DSK:AMIS.TRM[,]                         ';
    2: FileSpec := 'TED:AMIS.TRM                            ';
    3: FileSpec := 'AMIS.CHART                              ';
    4: FileSpec := 'TED:AMIS.DXC                            ';
    5: FileSpec := 'TED:AMIS.BHL                            ';
    6: FileSpec := 'DOC:AMIS.NEW                            ';
    7: FileSpec := 'DSK:AMIS.INI[,]                         ';
    *) (* Tops-10 file speces. *)
   (*@VMS:
    1: FileSpec := 'SYS$LOGIN:AMIS.TRM                      ';
    2: FileSpec := 'AMIS_DOC:AMIS.TRM                       ';
    3: FileSpec := 'AMIS.CHART                              ';
    4: FileSpec := 'AMIS_DOC:AMIS.DXC                       ';
    5: FileSpec := 'AMIS_DOC:AMIS.BHL                       ';
    6: FileSpec := 'AMIS_DOC:AMIS.NEW                       ';
    7: VGetFSpec(FileSpec);
    *) (* VMS file speces. *)
  end;
end;

(*---------------------------------------------------------------------------*)

(*@TOPS: begin end. *)
(*@VMS: end. *)
