(* AMIS keybord input module. *)	(* -*-PASCAL-*- *)

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

module input;

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
			
  HelpChar = CtrlUnderScore;

  CSI = 155;			(* Command Seq. introducer. *)

  StrSize = 40;

  (*@VMS: MacMax = 200; *)	(* Max length of Keyboard macro *)
  (*@TOPS: MacMax = 50; *)	(* Max length of Keyboard macro *)

type
  string = packed array [1..StrSize] of char;

  RefMacro = ^MacroRecord;
  MacroRecord = packed record
    Left, Right	: RefMacro;	(* Links in linked list *)
    Number	: integer;	(* Number of macro *)
    Size	: integer;	(* Number of chars in macro *)
    MacString	: array [1..MacMax] of integer;	(* Macro itself. *)
    Running	: boolean;	(* If this macro is running *)
    LoopCount	: integer;	(* Loopcounter for this run *)
    Pos		: integer;	(* Position for this loop *)
  end;

var
  LastChar	: char;         (* The last character read *)
  MetaChar	: boolean;	(* The last character was a meta-character *)
  CsiTerminator	: char;		(* Character terminating CSI seq. *)
  CsiArgument	: integer;	(* Numeric arg in CSI seq. *)
  Again		: boolean;      (* We should read the last character again *)
  Filing	: boolean;	(* We are reading from the init file *)
  FilPos	: integer;	(* Position in init file *)
  FilSiz	: integer;	(* Size of init file. *)
  MacroRunning	: boolean;	(* A Keyboard macro is running *)
  DefiningMacro	: boolean;	(* A Keyboard macro is being defined *)
  ZeroMacro	: RefMacro;	(* Points to head of kbd macro linked list *)
  RecLevel	: integer;	(* Recursion level for keyboard macros *)
  LastFrozen	: integer;	(* Number of last frozen keybord macro *)
  CurrentMacro	: RefMacro;	(* Points to currently running kbd macro *)

  AutoBuffer	: string;	(* Auto echo buffer. *)
  AutoCount	: integer;	(* Count of chars in auto echo buffer. *)
  AutoStarted	: boolean;	(* Auto echo has started. *)
  AutoEchoed	: boolean;	(* Current char is queued for echoing. *)

(*---------------------------------------------------------------------------*)

function  TtyRead: integer; external;
procedure TtyFlush; external;
function  TtyCheck(Seconds: integer): boolean; external;
procedure NoInt; external;
procedure OKInt; external;

procedure Bug(Msg: string); external;
procedure Error(Msg: string); external;

procedure DefMode(flag: boolean); external;
procedure CommandLoop(RecursiveName: string); external;
procedure TopLoop; external;

procedure EchoUpDate; external;
procedure WinUpDate; external;
procedure EchoSize(var x, y: integer); external;
procedure EchoPos(x, y: integer); external;
procedure EchoEol; external;
procedure EchoArrow(c: char); external;
procedure EchoString(s: string); external;
procedure WinOverWrite(c: char); external;
procedure OvWString(s: string); external;
procedure OvWLine; external;

function  QGetChar(reg, dot: integer): char; external;
function  QGetSize(reg: integer): integer; external;
procedure QX(reg, count: integer); external;

procedure EchoClear; forward;	(* Until it is moved to SCREEN. *)

(*---------------------------------------------------------------------------*)
(*  Automagical echo routines.                                               *)

procedure AutoDump;
var
  i: integer;
begin
  for i := 1 to AutoCount do begin
    AutoStarted := true;
    EchoArrow(AutoBuffer[i])
  end;
  AutoCount := 0;
end;

(*@VMS: [global] *)
procedure AutoImmediate;
begin
  if AutoCount > 0 then AutoDump;
  AutoStarted := true;
end;

(*@VMS: [global] *)
procedure AutoReset;
begin
  if AutoStarted		(* If any echoing was written out *)
  then EchoClear;		(* Clear the echo area *)
  AutoStarted := false;		(* Reset flag *)
  AutoCount := 0;		(* Reset buffer count *)
end;

(*@VMS: [global] *)
procedure AutoChar(c: char);
begin
  if AutoCount >= StrSize then AutoDump;
  if AutoStarted then begin
    EchoArrow(c);
  end else begin
    AutoCount := AutoCount + 1;
    AutoBuffer [AutoCount] := c;
  end;
end;

(*@VMS: [global] *)
procedure AutoLast(expand: boolean);

type word = packed array[1..10] of char;

  procedure AutoWord(w: word);
  var
    i: integer;
  begin
    for i := 1 to 10 do if w[i] <> ' ' then AutoChar(w[i]);
    AutoChar(' ');
  end;

begin
  if not AutoEchoed then begin
    AutoEchoed := true;
    if MetaChar then begin
      AutoChar('M'); AutoChar('-')
    end;
    if LastChar = chr(BackSpace) then AutoWord('Backspace ')
    else if LastChar = chr(HorizontalTab) then AutoWord('Tab       ')
    else if LastChar = chr(LineFeed) then AutoWord('Linefeed  ')
    else if LastChar = chr(CarriageReturn) then AutoWord('Return    ')
    else if LastChar = chr(Escape) then AutoWord('Escape    ')
    else if LastChar = chr(HelpChar) then AutoWord('Help      ')
    else if LastChar = ' ' then AutoWord('Space     ')
    else if LastChar = chr(Rubout) then AutoWord('Rubout    ')
    else if (LastChar < ' ') and expand then begin
      AutoChar('C'); AutoChar('-');
      AutoChar(chr(ord(LastChar) + 64)); AutoChar(' ');
    end else begin
      AutoChar(LastChar); AutoChar(' ');
    end;
    if AutoStarted then EchoUpDate;
  end;
end;

(*---------------------------------------------------------------------------*)
(*  Check for TTY input                                                      *)

(*@VMS: [global] *)
function Check(Time: integer): boolean;
begin
  Check := Again or filing or MacroRunning or TtyCheck(Time);
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure SetFile;
begin
  FilPos:=0;
  FilSiz:=QGetSize(-39);
  Filing:=FilSiz>0;
end;

function nextfile: integer;
var
  i: integer;
begin
  i:=ord(QGetChar(-39,FilPos));
  FilPos:=FilPos+1;
  nextfile:=i;
  if i = 13 then begin
    if FilSiz>FilPos then i:=ord(QGetChar(-39,FilPos));
    if i = 10 then FilPos:=FilPos+1;
  end;
  filing:=FilSiz>FilPos;
  if not filing then QX(-39,0);
end;

(*---------------------------------------------------------------------------*)
(*  The function NextMacro returns the next eight bit character from the     *)
(*  current running keybord macro.					     *)

function NextMacro: integer;
begin
  with CurrentMacro^ do begin
    if Pos > Size
    then Bug('INPUT: No end of Keyboard macro.        ');
    NextMacro := MacString [Pos];
    Pos := Pos + 1;
  end; (* with *)
end;

(*---------------------------------------------------------------------------*)
(*  The procedure NoMacDef aborts the current macro definition, if any.      *)

procedure NoMacDef;
begin
  DefMode(false);
  DefiningMacro := false;
end;

(*---------------------------------------------------------------------------*)
(*  The procedure KbdStart implements the function ^R Start Kbd Macro.       *)

(*@VMS: [global] *)
procedure KbdStart(Arg: integer);
begin
  if DefiningMacro or MacroRunning
  then begin			(* May not be started inside another *)
    NoMacDef;
    Error('RKM? Recursive Keyboard macro           ')
  end;
  if RecLevel > 0		(* Not allowed below a Kbd Macro Query *)
  then Error('MIR? But the macro is running           ');
  with ZeroMacro^ do begin
    Size := 0;
    LoopCount := arg;
  end; (* with *)
  CurrentMacro := ZeroMacro;
  DefiningMacro := true;	(* Now we are definig a macro. *)
  defmode(true);		(* ... tell MAIN for the modeline *)
end;

(*---------------------------------------------------------------------------*)
(*  The procedure KbdEnd implements the function ^R End Kbd Macro.           *)

(*@VMS: [global] *)
procedure KbdEnd(Arg: integer; ArgGiven: boolean);
begin
  if not (MacroRunning or DefiningMacro)
  then Error('NIB? Not inside a macro.                ');
  with CurrentMacro^ do begin
    if (DefiningMacro and ArgGiven)
    then LoopCount := Arg;
    Pos := 1;			(* Restart the macro *)
    LoopCount := LoopCount - 1;
    MacroRunning := (LoopCount <> 0);
  end; (* with *)
  NoMacDef;
end;

(*---------------------------------------------------------------------------*)

function FindKbdMacro(Number: integer): RefMacro;
var
  Test: RefMacro;
begin
  Test := ZeroMacro;
  if Number <> 0
  then repeat
    Test := Test^.Right;
    if Test = ZeroMacro
    then Bug('FindKbdMacro: Illegal argument.         ');
  until Test^.Number = Number;
  FindKbdMacro := Test;
end;

(*---------------------------------------------------------------------------*)
(*  This procedure does the job of the function ^R Execute Kbd Macro.        *)

(*@VMS: [global] *)
procedure KbdExecute(Number, Arg: integer);
begin
  if DefiningMacro or MacroRunning
  then begin
    NoMacDef;
    Error('RKM? Recursive Keyboard macro           ');
  end;
  if RecLevel > 0
  then Error('MIR? But the macro is running           ');
  CurrentMacro := FindKbdMacro(Number);
  with CurrentMacro^ do begin
    if Size = 0 then Error('NMD? No Keyboard Macro is defined.      ');
    Pos := 1;
    LoopCount := Arg;		(* Do it arg times *)
    MacroRunning := true;
  end; (* with *)
end;

(*---------------------------------------------------------------------------*)
(*  The procedure KbdView implements the function View Kbd Macro.            *)

(*@VMS: [global] *)
procedure KbdView(Number: integer);
var
  i: integer;
  c: char;
  m: RefMacro;
begin
  OvWString('Definition of keyboard macro:           ');
  OvWLine; OvWLine;
  m := FindKbdMacro(Number);
  with m^ do begin
    for i := 1 to Size do begin
      c := chr(MacString [i] mod 128);
      if (c < ' ') and (c <> chr(Escape)) and (c <> chr(CarriageReturn)) and
	 (c <> chr(HorizontalTab)) then
      begin
	WinOverWrite('C'); WinOverWrite('-');
	c := chr(ord(c) + 64);	(* Convert to writeable character *)
      end;
      if macstring [i] > 127
      then begin
	WinOverWrite('M'); WinOverWrite('-')
      end;
      if c = chr(Escape)
      then OvWString('Escape                                  ')
      else if c = ' '
      then OvWString('Space                                   ')
      else if c = chr(CarriageReturn)
      then OvWString('Return                                  ')
      else if c = chr(HorizontalTab)
      then OvWString('Tab                                     ')
      else if c = chr(Rubout)
      then OvWString('Rubout                                  ')
      else begin
	WinOverWrite(c); WinOverWrite(' ');
      end;
    end; (* for *)
  end; (* with *)
  OvWLine;
end;

(*---------------------------------------------------------------------------*)
(*  The function KbdFreeze saves the currently defined macro, and returns    *)
(*  a handle for later access.						     *)

(*@VMS: [global] *)
function KbdFreeze: integer;
var
  ThisMacro: RefMacro;
begin (* KbdFreeze *)
  NoInt;			(* Lock out interrupts *)
  LastFrozen := LastFrozen + 1;
  new(ThisMacro);
  with ThisMacro^ do begin
    Left := ZeroMacro;
    Right := ZeroMacro^.Right;
    MacString := ZeroMacro^.MacString;
    Size := ZeroMacro^.Size;
    Number := LastFrozen;
  end; (* with *)
  ZeroMacro^.Right := ThisMacro;
  ZeroMacro^.Right^.Left := ThisMacro;
  KbdFreeze := LastFrozen;
  OKInt;			(* Allow interrupts again *)
end; (* KbdFreeze *)

(*---------------------------------------------------------------------------*)
(*  The function KbdStop aborts macro definition, if any, and returns true   *)
(*  if there was a macro being defined.					     *)

(*@VMS: [global] *)
function KbdStop: boolean;
begin
  NoMacDef;
  RecLevel := 0;
  KbdStop := MacroRunning;
  MacroRunning := false;
end;

(*---------------------------------------------------------------------------*)
(*  The function KbdRunning checks if a Keybord macro is running.	     *)

(*@VMS: [global] *)
function KbdRunning: boolean;
begin
  KbdRunning := MacroRunning;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure GetCsiData(var arg: integer; var tc: char);
begin
  arg := CsiArgument;
  tc := CsiTerminator;
end;

(*---------------------------------------------------------------------------*)
(*  This function is the basic character reading routine.                    *)

(*@VMS: [global] *)
function QReadC: char;
var
  i: integer;

  procedure MacroSave;
  begin
    with ZeroMacro^ do begin
      Size := Size + 1;
      if Size > MacMax then begin (* Flush this macro if too long. *)
	Size := 0;
	Error('TLK? Too Long Keyboard macro            ');
      end;
      MacString [Size] := i;
    end; (* with *)
  end;

begin
  if not Again then begin
    if MacroRunning
    then i := nextmacro
    else begin
      if filing
      then i := nextfile
      else begin
	if AutoCount > 0 then	(* Any lazy echo? *)
	if not check(1) then begin (* Yes, input within a second? *)
	  AutoDump;		(* No, dump out all echos *)
	  EchoUpDate;		(* Force it out *)
	end;
	i := TtyRead;		(* Get a character from the user *)
      end;
      if DefiningMacro then MacroSave;
    end;
    if i = CSI then begin	(* Parse CSI arguments, if any. *)
      CsiArgument := 0;
      while QReadC in ['0'..'9'] do begin
	CsiArgument := CsiArgument * 10 + ord(LastChar) - ord('0');
      end;
      CsiTerminator := LastChar;
    end;
    AutoEchoed := false;	(* This char is not echoed yet. *)
    LastChar := chr(i mod 256);	(* Split into character and meta bit. *)
    MetaChar := i >= 256;
  end;
  Again := false;		(* Don't read this again unless told so *)
  QReadC := LastChar;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
function ReadC: char;
begin
  ReadC := QReadC;		(* Read a character *)
  if LastChar = chr(CtrlG)	(* Is it a ^G? *)
  then begin			(* Yes, abort if not meta bit on *)
    if not MetaChar
    then TopLoop;
  end;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
function MetaBit: boolean;
begin
  MetaBit := MetaChar;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure ReRead;
begin				(* Read last character again *)
  Again := true;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure Flush;
begin                           (* Flush all TTY buffers *)
  Again := false;
  TtyFlush;
end;

(*---------------------------------------------------------------------------*)
(*  This procedure implements the function ^R Kbd Macro Query                *)

(*@VMS: [global] *)
procedure KbdQuery;
var
  c: char;
begin (* KbdQuery *)
  if MacroRunning then		(* NOOP unless a macro is running *)
  begin
    MacroRunning := false;	(* Stop the macro temporarily *)
    EchoClear;
    EchoString('Kbd Query                               ');
    WinUpDate;
    c := QReadC;		(* Wait for the user to type something *)
    EchoClear;
    while ((c = Chr(HelpChar)) or (c = Chr(CtrlR)) or (c = Chr(CtrlL)))
	   and not metabit do
    begin
      if c = Chr(HelpChar)
      then begin		(* Print help for Keyboard Macro Query *)
	OvWString('You are entering an argument to         ');
	OvWString('a Keyboard Macro Query.                 '); OvWLine;
	OvWString('Enter one of the following:             '); OvWLine;
	OvWString('Space   => Continue                     '); OvWLine;
	OvWString('Escape  => Stop the Macro               '); OvWLine;
	OvWString('Rubout  => Skip the rest of the Macro   '); OvWLine;
	OvWString('C-R     => Enter recursive editing      '); OvWLine;
	OvWString('C-L     => Redisplay the screen         '); OvWLine;
	OvWString('Any other character will stop the Macro ');
	OvWString('and be reread again.                    '); OvWLine;
      end else begin
	if c = chr(CtrlR) then begin
	  RecLevel := RecLevel + 1; (* Enter recursive editing *)
	  CommandLoop('Kbd Query.                              ');
	  RecLevel := RecLevel - 1;
	  EchoClear;
	end;
	WinUpDate;
      end;
      EchoString('Kbd Query                               ');
      EchoUpDate;
      c := QReadC;
      EchoClear;
    end;
    if metabit then
      reread
    else
    if c = ' ' then		(* Space => continue *)
      MacroRunning := true
    else
    if c = Chr(rubout) then	(* Rubout => skip the rest *)
    begin
      MacroRunning := true;
      kbdend(0, false)
    end
    else
    if c <> Chr(escape) then	(* Escape => Stop the macro *)
      reread;
  end;
end; (* KbeQuery *)

(*---------------------------------------------------------------------------*)
(*  This procedure initializes the INPUT module.                             *)

(*@VMS: [global] *)
procedure InInit(Total: boolean);
begin
  Again := false;		(* Turn off character reread flag *)
  filing := false;		(* Not handling any init file *)
  MacroRunning := false;
  RecLevel := 0;		(* No recursion at initialization time *)
  DefiningMacro := false;	(* Halt macro definition if reinitialized *)
  AutoStarted := false;		(* Set lazy echo flags to something sensible *)
  AutoCount := 0;
  if Total then begin		(* First time? *)
    new(ZeroMacro);		(* Yes, set up macro header *)
    ZeroMacro^.Left := ZeroMacro;
    ZeroMacro^.Right := ZeroMacro;
    ZeroMacro^.Size := 0;
    ZeroMacro^.Number := 0;
    LastFrozen := 0;		(* Start freeze at zero *)
  end;
end;

(*---------------------------------------------------------------------------*)

(* ==> SCREEN *)

(*@VMS: [global] *)
procedure EchoClear;
var
  x, y: integer;
  i: integer;
begin
  EchoSize(x, y);		(* Get height of echo area *)
  for i := 0 to x-1 do
  begin
    EchoPos(i, 0);		(* Position cursor *)
    EchoEol;			(* Clear line *)
  end;
  EchoPos(0,0); 		(* Position at the echo area *)
  AutoStarted := false;
  AutoCount := 0;
end;

(*---------------------------------------------------------------------------*)

(*@TOPS: begin end. *)
(*@VMS: end. *)
