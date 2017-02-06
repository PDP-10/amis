(* AMIS screen handler. *)	(* -*- PASCAL -*- *)

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

(*$E+*)(*$T-*)

  (**********************************************************************)
  (*                       Module SCREEN of AMIS                        *)
  (*                                                                    *)
  (* This module is responsible for the screen that shows a section of  *)
  (* the buffer, the mode area and the echo area.                       *)
  (*                                                                    *)
  (*     Author: Anders Str|m                                           *)
  (*                                                                    *)
  (*     Last update: 1982-01-26 /AS                                    *)
  (*                                                                    *)
  (**********************************************************************)

module screen;

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

  strsize= 40;

  maxwidth= 132;
  maxheight= 72;
  modemaxheight= 1;
  echomaxheight= 1;
  pcntwidth= 9;

  rrbeg= 0;

type
  string= packed array[1..strsize] of char;
  bufpos= integer;
  charset = set of char;

  states= (newline, oldline, control, noline);
  linetext= packed array [0..maxwidth] of char;
  (* Window line status *)
  line= record
    show: linetext; showlen: integer; showpos: bufpos;
    updated: boolean;
  end;
  lstate= record
    bfpos: bufpos; state: states;
  end;
  statearr= array [0..maxheight] of lstate;
  (* Status for percent field *)
  pcmode= record
    mode: (bad, none, top, bot, pcent);
    val: integer;
    modif: boolean;
  end;

  CharImage = packed array [1..4] of char; (* What a character looks like. *)

  bmodes= (ok, pos, nopos);

var
  lines: array [0..maxheight] of line;
  curstate: statearr;
  (* Flag indicating vlidity of curstate *)
  (* OK - is OK, but changes might have happend *)
  (* pos - the position of winstart might be good *)
  (* nopos - need a wrepos followed by a build *)
  built: bmodes;

  (* Current size of screen *)
  screenheight, screenwidth: integer;

  (* Flag indicating that entire screen is blank *)
  csflg: boolean;
  (* Flag indicating that we should do a refresh *)
  dorefresh: boolean;

  (* Mark of where changes have occured *)
  first, last, count: bufpos;

  (* Total height of window *)
  winheight: integer;
  (* Top and bottom of selected window *)
  winfirst, winlast: integer;

  (* What we show in the window *)
  winstart, winend: bufpos;
  (* Current position in window *)
  hpos, vpos: integer; knownpos: boolean;
  (* Flag indicating that we may have simple case of updating *)
  simplep, noprelude: boolean; scount, spos: integer;

  (* Information about two window mode *)
  splitline: integer; (* Where to split window *)
  nwins: integer; (* Number of window *)
  curwin: integer; (* Current window (base 1) *)
  new_window, new_buffer: integer;
  xwinstart, xwinend, xdot: array [1..2] of bufpos;
  xbuilt: array [1..2] of bmodes;
  xok: array [1..2] of boolean;
  (* Currently selected buffer, and shown buffer *)
  curbuffer, showbuffer: array [1..2] of integer;

  (* Buffer values, as we know them *)
  rrdot, rrz: bufpos;

  modelines: array [0..modemaxheight] of linetext;
  (* Current top and height of mode area *)
  modetop, modeheight: integer;
  (* Current position in mode area *)
  moderow, modecol: integer;

  echolines: array [0..echomaxheight] of linetext;
  (* Current top and height of echo area *)
  echotop, echoheight: integer;
  (* Current position in echo area *)
  echorow, echocol: integer;

  (* Data for mode line clock *)
  ClockIsOn: boolean;		(* Knows if the clock is on or not *)
  ClockRow, ClockCol: integer;	(* Knows where in mode line clock is *)

  (* Percent field status *)
  pcfld: pcmode;
  (* Overwrite variables *)
  orow, ocol: integer;
  ovmode, ovflush: boolean;

  (* Cost for different operations, used to select an optimal *)
  (* update strategy, wrt these cost. The reference for costs *)
  (* are the cost of outputting one character, which costs 1. *)
  linecost: integer; (* Cost for updating one line *)
  scrollcost: integer; (* Cost for scrolling one line *)
  idcharcost: integer; (* Cost for inserting or deleting one character *)

  (* Flags telling what terminal features we can use. *)
  xyflag	: boolean;	(* We have Direct Cursor Adressing. *)
  eolflag	: boolean;	(* We have Erase to End Of Line. *)
  scrflag	: boolean;	(* We have Region Scroll. *)

  printable	: set of char;	(* What chars are printable. *)

  chrview	: array [char] of CharImage;
  chrvlen	: array [char] of 0..4;

  EolFirst	: char;		(* First char of EOL. *)
  EolLineFeed	: boolean;	(* TRUE if single Line Feed is EOL too. *)

  blanktext, messedtext: linetext;

  (****************************************)
  (*                                      *)
  (*     External procedures used         *)
  (*                                      *)
  (****************************************)

(* Module TTYIO *)

procedure ttyforce; external;
procedure bug(n: string); external;
procedure GetClock(var Hours, Minutes: integer); external;

(* Module BUFFER *)

function getdot: bufpos; external;
procedure setdot(pt: bufpos); external;
function getsize: bufpos; external;
function bgetchar(i: bufpos): char; external;
function getmodified: boolean; external;
function getlines(i: bufpos): bufpos; external;
procedure isetbuf(n: integer); external;
function ateol(i: bufpos; d: integer): boolean; external;
function eolsize: integer; external;
procedure EolString(var s: string; var i: integer); external;

(* Module TERM *)

procedure TrmSize(var rows, col: integer); external;
procedure TrmFeatures(var xyflag, eolflag, scrflag: boolean); external;
procedure TrmPrintable(var printable: charset); external;
procedure trmpos(row, col: integer); external;
procedure trmeol; external;
procedure trmout(c: char); external;
procedure trmscr(y1, y2, n: integer); external;
procedure trmclr; external;
procedure trminv; external;
procedure trmniv; external;
procedure trmich(c: char); external;
procedure trmdch; external;
procedure trmcst(var scrollcost, idcharcost: integer); external;
procedure TrmWhere(var row, col: integer); external;

(* Module INPUT *)

function kbdrunning: boolean; external;
function readc: char; external;
function check(t: integer): boolean; external;
procedure reread; external;

(* Module UTILITY *)

function StrLength(var Str: string): integer; external;

  (****************************************)
  (*                                      *)
  (*     Utilities in this module         *)
  (*                                      *)
  (****************************************)


procedure markmessed(i: integer);
begin
  with lines[i] do begin
    show:= messedtext; showlen:= screenwidth;
    updated:= false;
  end;
end;

procedure markblank(i: integer);
begin
  with lines[i] do begin
    showpos:= -1; show:= blanktext;
    showlen:= 0; updated:= false;
  end;
end;

  (**** STARTOFLINE ****)
function startofline(p: bufpos): bufpos;
  (* Find where the line containing p starts. *)
  (* If the line is more than a screenful, just get a pointer about *)
  (* a screen backwards *)
label 1;
var stop: integer;
begin (* startofline *)
  stop:= p-winheight*screenwidth;
  if stop<rrbeg then stop:= rrbeg;
  while p>stop do begin
    if ateol(p, -1) then goto 1;
    p:= p-1;
  end;
1:
  startofline:= p;
end (* startofline *);

  (**** WDOWNLINES ****)
function wdownlines(pt: bufpos; n: integer): bufpos;
  (* Starting at pt move n screen lines down, returning new position *)
label 1;
var h: integer; ch: char;
begin (* wdownlines *)
  h:= 0;
  if n<=0 then goto 1;
  while pt<rrz do begin
    ch:= bgetchar(pt);
    if EolLineFeed and (ch=chr(LineFeed)) then begin
      pt:= pt+1; h:= 0; n:= n-1;
      if n<=0 then goto 1;
    end else if ateol(pt, 1) then begin
      pt:= pt+eolsize; h:= 0; n:= n-1;
      if n<=0 then goto 1;
    end else begin
      if h>=(screenwidth-1) then begin
	h:= 0; n:= n-1;
	if n<=0 then goto 1;
      end;
      if ch in printable then begin
	h:= h+1;
      end else if ch=chr(HorizontalTab) then begin
	h:= (h div 8)*8+8;
	if h>=screenwidth then begin
	  h:= 0; n:= n-1;
	  if n<=0 then goto 1;
	end;
      end else if ch=chr(Escape) then begin
	h:= h+1;
      end else begin
	h:= h+2;
	if h>=screenwidth then begin
	  h:= h-screenwidth+1; n:= n-1;
	  if n<=0 then goto 1;
	end;
      end;
      pt:= pt+1;
    end;
  end;
1:
  wdownlines:= pt;
end (* wdownlines *);

  (**** WNLINES ****)
function wnlines(pt: bufpos): integer;
  (* computes number of window lines a text line needs *)
  (* starting at pt *)
label 1;
var h, v: integer; ch: char;
begin (* wnlines *)
  h:= 0; v:= 1;
  while pt<rrz do begin
    ch:= bgetchar(pt);
    if EolLineFeed then begin
      if ch = chr(LineFeed) then goto 1;
    end;
    if ch = EolFirst then begin
      if ateol(pt, 1) then goto 1;
    end;
    if h>=(screenwidth-1) then begin
      h:= 0; v:= v+1;
    end;
    if ch in printable then begin
      h:= h+1;
    end else if ch=chr(HorizontalTab) then begin
      h:= (h div 8)*8+8;
      if h>=screenwidth then begin
	h:= 0; v:= v+1;
      end;
    end else if ch=chr(Escape) then begin
      h:= h+1;
    end else begin
      h:= h+2;
      if h>=screenwidth then begin
	h:= h-screenwidth+1; v:= v+1;
      end;
    end;
    pt:= pt+1;
  end;
1:
  wnlines:= v;
end (* wnlines *);

  (**** WXNLINES ****)
function wxnlines(pt, pe: bufpos): integer;
  (* computes number of window lines needed for a text line, *)
  (* from pt to pe *)
var h, v: integer; ch: char;
begin (* wxnlines *)
  h:= 0; v:= 1;
  for pt:= pt to pe-1 do begin
    ch:= bgetchar(pt);
    if (h+1)>=screenwidth then begin
      h:= h-screenwidth+1; v:= v+1;
    end;
    if ch in printable then begin
      h:= h+1;
    end else if ch=chr(HorizontalTab) then begin
      h:= (h div 8)*8+8;
      if h>=screenwidth then begin
	h:= 0; v:= v+1;
      end;
    end else if ch=chr(Escape) then begin
      h:= h+1;
    end else begin
      h:= h+2;
      if h>=screenwidth then begin
	h:= h-screenwidth+1; v:= v+1;
      end;
    end;
  end;
  wxnlines:= v;
end (* wxnlines *);

  (**** WUPLINES ****)
function wuplines(pt: bufpos; n: integer): integer;
  (* Starting at pt move n screen-lines up, returning new position *)
var p: bufpos;
begin (* wuplines *)
  p:= startofline(pt);
  n:= n+1-wxnlines(p, pt);
  while (p>rrbeg) and (n>0) do begin
    p:= startofline(p-2); n:= n-wnlines(p);
  end;
  if n<0 then p:= wdownlines(p, -n);
  wuplines:= p;
end (* wuplines *);

  (**** WREPOS ****)
procedure wrepos(goalline: integer);
  (* Reposition the window, gives new value to WINSTART *)
begin (* wrepos *)
  winstart:= wuplines(rrdot, goalline-winfirst);
  built:= pos;
end (* wrepos *);

  (**** BUILDLINE ****)
procedure buildline(v: integer);
label 1;
var ch: char; h: integer; sflg: states; pt: bufpos;
begin (* buildline *)
  with curstate[v] do begin
    sflg:= state; pt:= bfpos;
  end;
  h:= 0; if sflg=control then h:= 1;
  while true do begin
    (* loop over characters *)
    if pt=rrdot then begin
      hpos:= h; vpos:= v; knownpos:= true;
    end;
    if pt>=rrz then begin
      pt:= rrz+1; sflg:= noline; goto 1;
    end;
    ch:= bgetchar(pt);
    if EolLineFeed then begin
      if ch = chr(LineFeed) then begin
	pt:= pt+1; sflg:= newline; goto 1;
      end;
    end;
    if ch = EolFirst then begin
      if ateol(pt, 1) then begin
	pt:= pt+eolsize; sflg:= newline; goto 1;
      end;
    end;
    if h=(screenwidth-1) then begin
      sflg:= oldline; goto 1;
    end else if ch in printable then begin
      h:= h+1; pt:= pt+1;
    end else if ch=chr(HorizontalTab) then begin
      h:= (h div 8)*8+8; pt:=pt+1;
      if h>=screenwidth then begin
	sflg:= oldline; goto 1;
      end;
    end else if ch=chr(Escape) then begin
      h:= h+1; pt:= pt+1;
    end else begin
      h:= h+2; pt:= pt+1;
      if h>=screenwidth then begin
	sflg:= control; goto 1;
      end;
    end;
  end (* WHILE loop over characters*);
1:
  with curstate[v+1] do begin
    state:= sflg; bfpos:= pt;
  end;
  if v=winlast then winend:= pt-1;
  lines[v].updated:= false;
end (* buildline *);

  (**** WBUILD ****)
procedure wbuild;
var i: integer;
begin (* wbuild *)
  knownpos:= false;
  with curstate[winfirst] do begin
    bfpos:= winstart; state:= newline;
  end;
  for i:= winfirst to winlast do buildline(i);
  built:= ok;
end (* wbuild *);

  (**** TryScroll ****)
procedure tryscroll(v: integer);
  (* Try to get things better by scrolling *)
label 1, 9;
var v0, i: integer; pt: bufpos;
begin (* tryscroll *)
  (* 1. If we are at end of buffer, do nothing *)
  (* 2. Try scrolling up or down *)
  pt:= curstate[v].bfpos; if pt>=rrz then goto 9;
  if v>winlast then goto 9;
  for v0:= winfirst to winlast do begin
    if lines[v0].showpos=pt then goto 1;
  end;
  v0:= v;
  pt:= lines[v0].showpos; if pt>=rrz then goto 9;
  for v:= winfirst to winlast do begin
    if curstate[v].bfpos=pt then goto 1;
  end;
  goto 9;
1:
  if v0>v then begin (* Scroll up *)
    if (v0-v)*scrollcost>(winlast+1-v0)*linecost then goto 9;
    trmscr(v, winlast, v0-v);
    for i:= v to winlast+v-v0 do begin
      lines[i]:= lines[i+v0-v];
      lines[i].updated:= false;
    end;
    for i:= winlast+1+v-v0 to winlast do markblank(i);
  end else if v0<v then begin (* Scroll down *)
    if (v-v0)*scrollcost>(winlast+1-v)*linecost then goto 9;
    trmscr(v0, winlast, v0-v);
    for i:= winlast downto v do begin
      with lines[i] do begin
	showpos:= lines[i+v0-v].showpos;
	show:= lines[i+v0-v].show;
	showlen:= lines[i+v0-v].showlen;
	updated:= false;
      end;
    end;
    for i:= v0 to v-1 do markblank(i);
  end;
9:
end (* tryscroll *);

  (**** PARTBUILD ****)
procedure partbuild;
label 1, 2, 3, 9;
var
  v, v1, v2: integer; bp: bufpos;
  oldstate: statearr;
begin
  (* Copy curstate to oldstate, updating values *)
  (* to use new buffer positons. *)
  for v:= winfirst to winlast+1 do begin
    oldstate[v].state:= curstate[v].state;
    bp:= curstate[v].bfpos;
    if bp>=first then begin
      bp:= bp+count;
      if bp<last then bp:= -1
    end;
    oldstate[v].bfpos:= bp;
  end;
  (* Find first line after first change *)
  for v1:= winfirst+1 to winlast+1 do begin
    if curstate[v1].bfpos>=first then goto 1;
    (* The predicate:
	 (bfpos>first) or ((bfpos=first) and (state<>newline))
       gives a cheaper computation below, but more cost for
       the predicate. *)
  end;
  (* Change is entirely after window. *)
  goto 9;
1:
  if curstate[v1].bfpos>first then begin
    v1:= v1-1;
  end else if curstate[v1].state<>newline then begin
    v1:= v1-1;
  end;
  (* Build lines past last change *)
  for v2:= v1 to winlast do begin
    with curstate[v2] do begin
      if bfpos>=last then begin
	if (state=newline) or (state=noline) then goto 2;
      end;
    end;
    buildline(v2);
  end;
  (* Change extends after window. *)
  goto 9;
2:
  (* Test if rest of window can be left as it is. *)
  if ((curstate[v2].bfpos = oldstate[v2].bfpos) and
      (curstate[v2].state = oldstate[v2].state)) then begin
    for v:= v2+1 to winlast+1 do curstate[v]:= oldstate[v];
    goto 9;
  end;
  (* Could not, thats bad. Try find how much it changed. *)
  for v:= v1 to winlast+1 do begin
    if ((curstate[v2].bfpos = oldstate[v].bfpos) and
        (curstate[v2].state = oldstate[v].state)) then goto 3;
  end;
  (* Could not find any match, try our last chance *)
  (* Maybe position after last wasn't start of a line before *)
  if curstate[v2].bfpos=last then begin
    buildline(v2); v2:= v2+1; goto 2;
  end;
  (* do it really hard. *)
  for v2:= v2 to winlast+1 do buildline(v2);
  goto 9;
3:
  (* Screen is shifted. *)
  v1:= v-v2;
  if v1>0 then begin
    (* Shifted up, so shift information up. *)
    for v:= v2 to winlast+1-v1 do begin
      curstate[v]:= oldstate[v+v1];
      lines[v].updated:= false;
    end;
    (* Then build rest of window the hard way. *)
    for v:= winlast+1-v1 to winlast do buildline(v);
  end else begin
    (* Shifted down, so shift information down. *)
    for v:= v2 to winlast+1 do begin
      curstate[v]:= oldstate[v+v1];
      lines[v].updated:= false;
    end;
  end;
  if scrflag then tryscroll(v2);
9:
  (* Window end might have moved. *)
  winend:= curstate[winlast+1].bfpos-1;
end (* partbuild *);

  (**** UPDATELINE ****)
procedure updateline(v: integer; var newline: linetext);
label 1;
var
  len, h, hmax: integer; ch, ch0, ch1: char;

begin (* updateline *)
  len:= 0;
  for h:= 0 to screenwidth-1 do if newline[h] <> ' ' then len:= h+1;
  hmax:= -1; ch0:= ' '; ch1:= ' ';
  with lines[v] do begin
    if xyflag then begin
      for h:=0 to len-1 do begin
	ch:= newline[h];
	if ch<>show[h] then begin
	  if (hmax=-1) or (h-hmax>3) then begin
	    trmpos(v, h);
	  end else begin
	    if (h-hmax)>2 then trmout(ch1);
	    if (h-hmax)>1 then trmout(ch0);
	  end;
	  trmout(ch); hmax:= h;
	end;
	ch1:= ch0; ch0:= ch;
      end;
    end else begin
      h:= 0;
      while newline[h]=show[h] do begin
	h:= h+1; if h>=len then goto 1;
      end;
      trmpos(v, h);
      for h:= h to len-1 do trmout(newline[h]);
    end;
1:
    if len<showlen then begin
      trmpos(v, len);
      if eolflag then begin
	trmeol;
      end else begin
	for h:= len to showlen-1 do trmout(' ');
      end;
    end;
  end;
  with lines[v] do begin
    updated:= true; showlen:= len; show:= newline;
  end;
end (* updateline *);

  (**** WUPDL ****)
procedure wupdl(v: integer);
  (* Update a line in the window section. *)
label 1, 2, 9;
var
  newline: linetext; len: integer;
  h, hmax: integer; ch, ch0, ch1: char;
  pt: bufpos;

begin (* wupdl *)
  if v>=winheight then bug('Internal error V>=WINHEIGHT in SCREEN/AS');
  if (nwins=2) and (v=splitline) then begin
    newline:= blanktext;
    for h:= 0 to (screenwidth-10) do newline[h]:= '-';
  end else if (v<winfirst) or (v>winlast) then begin
    goto 9;
  end else begin
    newline:= blanktext;
    h:= 0; pt:= curstate[v].bfpos;
    if curstate[v].state=control then begin
      ch:= bgetchar(pt-1);
      if ch=chr(RubOut) then begin
	newline[0]:= '?';
      (*@VMS: end else if ch>chr(RubOut) then begin newline[0]:= '*'; *)
      end else begin
	newline[0]:= chr(ord(ch)+64);
      end;
      h:= 1; len:= 1;
    end;
    while (pt<rrz) do begin
      ch:= bgetchar(pt);
      if EolLineFeed then begin
	if ch = chr(LineFeed) then goto 2;
      end;
      if ch = EolFirst then begin
	if ateol(pt, 1) then goto 2;
      end;
      pt:= pt+1;
      if h>=(screenwidth-1) then goto 1;
      if ch in printable then begin
	newline[h]:= ch; h:= h+1;
	if ch<>' ' then len:= h;
      end else if ch=chr(HorizontalTab) then begin
	h:= (h div 8)*8+8;
	if h>=screenwidth then goto 1;
      end else if ch=chr(Escape) then begin
	newline[h]:= '$'; h:= h+1; len:= h;
      end else begin
	newline[h]:= '^'; h:= h+1;
	if h>=(screenwidth-1) then goto 1;
	if ch=chr(RubOut) then begin
	  newline[h]:= '?';
	(*@VMS: END ELSE IF ch>chr(RubOut) THEN BEGIN newline[h]:= '*'; *)
	end else begin
	  newline[h]:= chr(ord(ch)+64);
	end;
	h:= h+1; len:= h;
      end;
    end (* WHILE *);
    goto 2;
1:
    newline[screenwidth-1]:= '!';
    len:= screenwidth;
2:
    lines[v].showpos:= curstate[v].bfpos;
  end;
  updateline(v, newline);
9:
end (* wupdl *);

  (**** WSETPOS ****)
procedure wsetpos;
var ch: char; p: bufpos;
begin (* wsetpos *)
  vpos:= winfirst+1;
  while (rrdot>=curstate[vpos].bfpos) and (vpos<=winlast) do vpos:= vpos+1;
  if rrdot>=curstate[vpos].bfpos then begin
    bug('WSETPOS outside window (in SCREEN)/AS   ');
  end;
  vpos:= vpos-1; hpos:= 0;
  with curstate[vpos] do begin
    p:= bfpos;
    if state=control then hpos:= 1;
  end;
  while p<rrdot do begin
    ch:= bgetchar(p);
    if EolLineFeed and (ch=chr(LineFeed)) then begin
      hpos:= 0; p:= p+1;
    end else if ateol(p, 1) then begin
      hpos:= 0; p:= p+eolsize;
    end else begin
      p:= p+1;
      if ch in printable then begin
	hpos:= hpos+1;
      end else if ch=chr(HorizontalTab) then begin
	hpos:= (hpos div 8)*8+8;
      end else if ch=chr(Escape) then begin
	hpos:= hpos+1
      end else begin
	hpos:= hpos+2;
      end;
    end;
  end;
  knownpos:= true;
end (* wsetpos *);

  (**** WUPD1 ****)
procedure wupd1;
  (* Make sure all information about what should be in window is correct. *)
var i: integer;
begin (* wupd1 *)
  if curbuffer[curwin]<>showbuffer[curwin] then begin
    built:= nopos;
    rrdot:= getdot; rrz:= getsize;
    first:= rrbeg; last:= rrz; count:= 0;
    showbuffer[curwin]:= curbuffer[curwin];
  end;
  for i:= winfirst to winlast do begin
    with lines[i] do begin
      if showpos>=first then begin
	showpos:= showpos+count;
	if showpos<last then showpos:= -1
      end;
    end;
  end;
  if built=pos then begin
    if rrdot>=winstart then wbuild;
  end else if (built=ok) and (last>=first) then begin
    partbuild;
  end;
  if (rrdot<winstart) or (rrdot>winend) or (built=nopos) then begin
    if (not eolflag) and (nwins=1) then dorefresh:= true;
    wrepos((winfirst+winlast) div 2); wbuild;
    if (rrdot<winstart) or (rrdot>winend) then begin
      bug('Dot outside window in WUPD1 (SCREEN)/AS ');
    end;
  end;
  last:= rrbeg; first:= rrz; count:= 0;
end (* wupd1 *);

  (**** PCNTUPDATE ****)
procedure pcntupdate;
  (* Update percent field *)
var npcfld: pcmode; pcntrow, pcntcol: integer;
begin (* pcntupdate *)
  with npcfld do begin
    pcntrow:= modeheight-1;
    pcntcol:= screenwidth-pcntwidth-1; val:= 0;
    if winend=rrz then begin
      if winstart=rrbeg then begin
	mode:= none;
      end else begin
	mode:= bot;
      end;
    end else if winstart=rrbeg then begin
      mode:= top;
    end else begin
      mode:= pcent;
      val:= (100*winstart) div rrz;
    end;
    modif:= getmodified;
  end;
  if ((npcfld.mode<>pcfld.mode) or (npcfld.val<>pcfld.val)
      or (npcfld.modif<>pcfld.modif)) then begin
    lines[modetop+pcntrow].updated:= false;
    with npcfld do begin
      if mode<>none then begin
	modelines[pcntrow][pcntcol  ]:= '-';
	modelines[pcntrow][pcntcol+1]:= '-';
	case mode of
	pcent:
	  begin
	    modelines[pcntrow][pcntcol+2]:= chr((val div 10)+ord('0'));
	    modelines[pcntrow][pcntcol+3]:= chr((val mod 10)+ord('0'));
	    modelines[pcntrow][pcntcol+4]:=  '%';
	  end;
	top:
	  begin
	    modelines[pcntrow][pcntcol+2]:= 'T';
	    modelines[pcntrow][pcntcol+3]:= 'O';
	    modelines[pcntrow][pcntcol+4]:= 'P';
	  end;
	bot:
	  begin
	    modelines[pcntrow][pcntcol+2]:= 'B';
	    modelines[pcntrow][pcntcol+3]:= 'O';
	    modelines[pcntrow][pcntcol+4]:= 'T';
	  end;
	end (* case *);
	modelines[pcntrow][pcntcol+5]:= '-';
	modelines[moderow][pcntcol+6]:= '-';
	pcntcol:= pcntcol+7;
      end;
      if modif then begin
	modelines[pcntrow][pcntcol  ]:= ' ';
	modelines[pcntrow][pcntcol+1]:= '*';
	pcntcol:= pcntcol+2;
      end;
      for pcntcol:= pcntcol to screenwidth-1 do begin
	modelines[pcntrow][pcntcol]:= ' ';
      end;
    end;
    pcfld:= npcfld;
  end;
end (* pcntupdate *);

  (**** NEWOWLINE ****)
procedure newowline(row: integer);
var i, morerow, morecol: integer; c: char;
begin (* newowline *)
  ocol:= 0; orow:= row;
  if orow > winlast then begin
    pcfld.mode:= bad;
    morerow:= modeheight-1;
    morecol:= screenwidth-pcntwidth-1;
    modelines[morerow][morecol  ]:= '-';
    modelines[morerow][morecol+1]:= '-';
    modelines[morerow][morecol+2]:= 'M';
    modelines[morerow][morecol+3]:= 'O';
    modelines[morerow][morecol+4]:= 'R';
    modelines[morerow][morecol+5]:= 'E';
    modelines[morerow][morecol+6]:= '-';
    modelines[morerow][morecol+7]:= '-';
    modelines[morerow][morecol+8]:= ' ';
    updateline(modetop+morerow, modelines[morerow]);
    trmpos(modetop+morerow, screenwidth-1);
    c:= readc;			(* Wait for the user to type something *)
    if c<>' ' then begin	(* If he didn't type a space *)
      ovflush:= true;		(* Set flushed flag *)
      modelines[morerow][morecol  ]:= 'F';
      modelines[morerow][morecol+1]:= 'L';
      modelines[morerow][morecol+2]:= 'U';
      modelines[morerow][morecol+3]:= 'S';
      modelines[morerow][morecol+4]:= 'H';
      modelines[morerow][morecol+5]:= 'E';
      modelines[morerow][morecol+6]:= 'D';
      modelines[morerow][morecol+7]:= ' ';
      modelines[morerow][morecol+8]:= ' ';
      updateline(modetop+morerow, modelines[morerow]);
      ttyforce;			(* Force the line out *)
      if c<>chr(RubOut) then reread; (* Reread all flush chars except rubout *)
    end else begin
      orow:= winfirst;
    end;
  end;
  if not ovflush then begin
    trmpos(orow, 0);
    if eolflag then begin
      trmeol;
    end else begin
      for i:= 1 to lines[orow].showlen do trmout(' ');
      trmpos(orow, 0);
    end;
    markblank(orow);
  end;
end (* newowline *);

procedure wupd0;
label
  9;
var
  i: integer;
begin
  if scrflag then tryscroll(winfirst);
  if check(0) then goto 9;
  if not knownpos then wsetpos;
  if not lines[vpos].updated then wupdl(vpos);
  if csflg then begin
    csflg:= false;
    for i:= 1 to winheight do begin
      if vpos+i<winheight then begin
	if not lines[vpos+i].updated then begin
	  wupdl(vpos+i);					
	  if check(0) then goto 9					
	end;
      end;							
      if vpos-i>=0 then begin
	if not lines[vpos-i].updated then begin	
	  wupdl(vpos-i);					
	  if check(0) then goto 9;
	end;
      end;
    end;
  end else begin
    for i:= 0 to winheight-1 do begin
      if not lines[i].updated then begin
	wupdl(i);
	if check(0) then goto 9;
      end;
    end;
  end;
9:
end;

procedure winprelude(unsimplify: boolean);
label
  9;
var
  i: integer;
begin
  if noprelude then goto 9;
  noprelude:= true;
  (* Four cases: *)
  (* 0/ Same window and same buffer *)
  (* 1/ Same window with other buffer *)
  (* 2/ Other window with same buffer as last in this window *)
  (* 3/ Other window with changed buffer *)
  (* Case 0 is ignored, case 1 requires just a reset of variables, *)
  (* case 3 is like case 1 after switching window, *)
  (* case 2 requires resetting dot to same position as last time *)
  if (new_window<>curwin) or (new_buffer<>curbuffer[curwin]) then begin
    unsimplify:= true;
    if new_window<>curwin then begin
      xwinstart[curwin]:= winstart; xwinend[curwin]:= winend;
      xbuilt[curwin]:= built; xdot[curwin]:= rrdot;
      if (first<=last) or (built<>ok) then xok[curwin]:= false;
      curwin:= new_window;
      if curwin=1 then begin
	winfirst:= 0; winlast:= splitline-1;
      end else begin
	winfirst:= splitline+1; winlast:= winheight-1;
      end;
      winstart:= xwinstart[curwin]; winend:= xwinend[curwin];
      built:= xbuilt[curwin]; knownpos:= false;
      rrdot:= xdot[curwin]; rrz:= getsize;
      (* Case 3 done, check for case 2 *)
      if curbuffer[curwin]=new_buffer then begin
	if rrdot>rrz then rrdot:= rrz;
	setdot(rrdot);
	if built<pos then built:= pos;
      end else begin
	rrdot:= getdot; built:= nopos;
      end;
    end;
    curbuffer[curwin]:= new_buffer;
    rrz:= getsize; rrdot:= getdot;
  end;
  if unsimplify then begin
    if scount>0 then begin
      for i:= spos+1 to winlast+1 do begin
	with lines[i] do showpos:= showpos+scount;
	with curstate[i] do bfpos:= bfpos+scount;
      end;
    end;
    simplep:= false; scount:= 0;
  end;
  noprelude:= false;
9:
end;

procedure wswitch;
  (* Switch window, including switch of buffer *)
begin
  new_window:= 3-new_window; new_buffer:= curbuffer[new_window];
  if new_buffer=0 then bug('No buffer selected for this window /AS  ');
  isetbuf(new_buffer);
  winprelude(true);
end;

procedure UpdModeLines;
var i: integer;
begin
  for i:= 0 to modeheight-1 do begin
    if not lines[modetop+i].updated then begin
      updateline(modetop+i, modelines[i]);
(***  IF check(0) THEN GOTO 9; ***)
    end;
  end;
end (* UpdModeLines *);

  (****************************************)
  (*                                      *)
  (*     Entries to this module           *)
  (*                                      *)
  (****************************************)

  (**** WININSERT ****)
(*@VMS: [global] *)
procedure wininsert(n: bufpos);
  (* n characters inserted at dot *)
begin (* wininsert *)
  winprelude(false);
  if first>rrdot then first:= rrdot;
  rrdot:= rrdot+n; rrz:= rrz+n;
  last:= last+n;
  if rrdot>last then last:= rrdot;
  count:= count+n;
  knownpos:= false;
end (* wininsert *);

  (**** WINDELETE ****)
(*@VMS: [global] *)
procedure windelete(n: bufpos);
  (* n characters deleted at dot *)
begin (* windelete *)
  winprelude(true);
  if first>rrdot then first:= rrdot;
  rrz:= rrz-n;
  last:= last-n;
  if rrdot>last then last:= rrdot;
  count:= count-n;
  knownpos:= false;
end (* windelete *);

  (**** WINSETDOT ****)
(*@VMS: [global] *)
procedure winsetdot(pt: bufpos);
  (* Dot is set to pt *)
begin (* winsetdot *)
  winprelude(true);
  rrdot:= pt;
  knownpos:= false;
end (* winsetdot *);

  (**** WINPOS ****)
(*@VMS: [global] *)
procedure winpos(row: integer);
  (* Position window so that dot is on specified row *)
begin (* winpos *)
  winprelude(true);
  if row<0 then begin
    row:= winlast+1+row;
    if row>=winfirst then wrepos(row);
  end else begin
    row:= winfirst+row;
    if row<=winlast then wrepos(row);
  end;
end (* winpos *);

  (**** WINSCROLL ****)
(*@VMS: [global] *)
procedure winscroll(n: integer);
  (* Scroll window n lines up or down *)
begin (* winscroll *)
  winprelude(true);
  wupd1; (* Make sure Winstart and Winend are OK *)
  if not knownpos then wsetpos;
  if n<0 then begin
    winstart:= wuplines(winstart, -n);
    if vpos-n>winlast then setdot(winstart);
  end else begin
    winstart:= wdownlines(winstart, n);
    if vpos-n<winfirst then setdot(winstart);
  end;
  built:= pos;
end (* winscroll *);

  (**** WINSELECT ****)
(*@VMS: [global] *)
procedure winselect(n: integer);
var cb: integer;
begin (* winselect *)
  if nwins=2 then begin
    if n=0 then begin
      new_window:= 3-new_window;
    end else begin
      new_window:= n;
    end;
    (* This seems to have "interesting" effects.  Therefore, figure *)
    (* out something else.   Later, that is... *)
    (* winprelude(true); *)
  end;
end (* winselect *);

  (**** WINBUF ****)
(*@VMS: [global] *)
procedure winbuf(n: integer);
  (* This is to inform us that current buffer has changed. *)
begin (* winbuf *)
  new_buffer:= n;
end (* winbuf *);

  (**** WINGROW ****)
(*@VMS: [global] *)
procedure wingrow(n: integer);
  (* Grow (or shrink) current window *)
var i, o: integer;
begin (* wingrow *)
  winprelude(true);
  if curwin=2 then begin
    n:= splitline-n;
  end else begin
    n:= splitline+n;
  end;
  if n<1 then n:= 1;
  if n>(winheight-2) then n:= winheight-2;
  o:= splitline; splitline:= n;
  if nwins=2 then begin
    if curwin=1 then begin
      winlast:= n-1;
    end else begin
      winfirst:= n+1;
    end;
    if built<pos then built:= pos;
    xok[1]:= false; xok[2]:= false;
    with lines[n] do begin
      updated:= false; showpos:= -1;
    end;
    if curwin=1 then begin
      wswitch;
      winscroll(o-n);
      wswitch;
    end else begin
      winscroll(n-o);
    end;
  end;
end (* wingrow *);

  (**** WINNO ****)
(*@VMS: [global] *)
procedure winno(n: integer);
  (* Tells us how many windows to use, current maximum 2 *)
var
  i: integer;
begin (* winno *)
  winprelude(true);
  if n=1 then begin
    if curwin<>1 then bug('Window one not selected /as             ');
    nwins:= 1; winfirst:= 0; winlast:= winheight-1;
    if built<pos then built:= pos;
  end else if n=2 then begin
    if nwins<>2 then begin
      xwinstart[2]:= 0; xwinend[2]:= 0;
      xbuilt[2]:= nopos; xdot[2]:= 0;
      nwins:= 2; new_window:= 2;
      if splitline<1 then splitline:= 1;
      if splitline>(winheight-2) then splitline:= winheight-2;
      winlast:= splitline-1;
      if built<pos then built:= pos;
      xok[1]:= false; xok[2]:= false;
      with lines[splitline] do begin
	updated:= false; showpos:= -1;
      end;
    end;
  end else begin
    bug('Illegal argument to WINNO /as           ');
  end;
end (* winno *);

  (**** WINCUR ****)
(*@VMS: [global] *)
function wincur: integer;
begin (* wincur *)
  wincur:= curwin;
end (* wincur *);

  (**** WINREFRESH ****)
(*@VMS: [global] *)
procedure winrefresh;
  (* Tells us that it is time to refresh the window *)
  (* It is our responsibility to position the window *)
var i: integer;
begin (* winrefresh *)
  winprelude(true);
  rrdot:= getdot; rrz:= getsize;
  if not dorefresh then wrepos((winfirst+winlast) div 2);
  trmclr;
  pcfld.mode:= bad; csflg:= true;
  for i:= 0 to screenheight do markblank(i);
  xok[1]:= false; xok[2]:= false;
end (* winrefresh *);

  (**** WINREWRITE ****)
(*@VMS: [global] *)
procedure winrewrite(n: integer);
  (* Rewrite n lines around current line *)
var i, low, high: integer;
begin (* winrewrite *)
  winprelude(true);
  if built=ok then begin
    if (rrdot>=winstart) and (rrdot<=winend) then begin
      if not knownpos then wsetpos;
      if n<1 then n:= 1;
      low:= vpos-((n-1) div 2);
      if low<0 then low:= 0;
      high:= low+n-1;
      if high>winlast then high:= winlast;
      for i:= low to high do markmessed(i);
    end;
  end;
end (* winrewrite *);

  (**** WINUPDATE ****)
(*@VMS: [global] *)
procedure winupdate;
  (* here we are allowed to do updating *)
label 1, 9;
var i: integer; c: char;
begin (* winupdate *)
  winprelude(false);
  if simplep then begin
    trmpos(vpos, hpos);
    while first<last do begin
      c:= bgetchar(first);
      if not (c in printable) then goto 1;
      if hpos>=screenwidth-1 then goto 1;
      trmout(c);
      with lines[vpos] do begin
	show[hpos]:= c; showlen:= hpos+1;
      end;
      hpos:= hpos+1; spos:= vpos;
      first:= first+1; count:= count-1; scount:= scount+1;
    end;
    knownpos:= true; ttyforce; goto 9;
1:
    winprelude(true);
  end;
  if ovmode then begin
    (* Wait for the user to type something *)
    c:= readc;
    if c<>' ' then reread;
  end;
  orow:= winfirst;			(* Reset overwrite lines *)
  ovmode:= false; ovflush:= false;
  if check(0) then goto 9;
  xok[curwin]:= false;
  wupd1;
  if dorefresh then begin
    winrefresh; dorefresh:= false;
  end;
  for i:= 0 to echoheight-1 do begin
    if not lines[echotop+i].updated then begin
      updateline(echotop+i, echolines[i]);
      if check(0) then goto 9;
    end;
  end;
  pcntupdate;
  UpdModeLines;
  if check(0) then goto 9;
  wupd0;
  if check(0) then goto 9;
  xok[curwin]:= true;
  if nwins=2 then begin
    if not xok[3-curwin] then begin
      wswitch;
      if built<pos then built:= pos;
      wupd1; wupd0;
      wswitch;
      last:= rrbeg; first:= rrz; count:= 0;
      if check(0) then goto 9;
      xok[3-curwin]:= true;
    end;
  end;
  if not knownpos then wsetpos;
  trmpos(vpos, hpos); ttyforce; (* Force, just like Echoupdate. / JMR *)
  simplep:= (ateol(rrdot, 1) or (rrdot=rrz)) and pcfld.modif;
9:
end (* winupdate *);

  (**** WINOVTOP ***)
(*@VMS: [global] *)
procedure winovtop;
  (* Starts new overwrite at top left cornet *)
begin (* winovtop *)
  winprelude(true);
  if not ovflush then begin
    ovmode:= true;
    newowline(winfirst);
  end;
end (* winovtop *);

  (**** WINOVERWRITE ****)
(*@VMS: [global] *)
procedure winoverwrite(ch: char);
  (* overwrites text in buffer with garbage *)
label 9;
begin (* winoverwrite *)
  winprelude(true);
  if ovflush then goto 9;
  if not ovmode then begin
    ovmode:= true;
    newowline(orow);
  end;
  if (ch<' ') or (ch=chr(RubOut)) then begin
    if ch=chr(LineFeed) then begin
      newowline(orow+1);
    end else if ch=chr(CarriageReturn) then begin
      ocol:= 0;
    end else if ch=chr(HorizontalTab) then begin
      ocol:= (ocol div 8)*8+8;
    end else begin
      winoverwrite('^');
      if ch=chr(RubOut) then begin
	winoverwrite('?');
      end else begin
	winoverwrite(chr(ord(ch)+64));
      end;
    end;
  end else begin
    if ocol>screenwidth-1 then begin
      newowline(orow+1);
    end;
    trmpos(orow, ocol);
    with lines[orow] do begin
      show[ocol]:= ch;
      trmout(ch);
      ocol:= ocol+1;
      if ocol>showlen then showlen:= ocol;
    end;
  end;
9:
end (* winoverwrite *);

  (**** WINOVCLEAR ****)
(*@VMS: [global] *)
procedure winovclear;
  (* Reset overwritemode *)
begin (* winovclear *)
  winprelude(true);
  ovmode:= false; ovflush:= false;
end (* winovclear *);

  (**** PCNTMESSED ****)
(*@VMS: [global] *)
procedure pcntmessed;
  (* Indicate that percent field is messed *)
begin (* pcntmessed *)
  winprelude(true);
  pcfld.mode:= bad;
end (* pcntmessed *);

  (**** WINTOP ****)
(*@VMS: [global] *)
function wintop: bufpos;
  (* Returns the position of the beginning of the window *)
begin (* wintop *)
  wintop:= winstart;
end (* wintop *);

  (**** WINSIZE ****)
(*@VMS: [global] *)
procedure winsize(var height, width: integer);
  (* Returns the size of the window *)
begin (* winsize *)
  height:= winlast-winfirst+1; width:= screenwidth;
end (* winsize *);

  (**** DOTPOS ****)
(*@VMS: [global] *)
procedure dotpos(var row, col: integer);
  (* Return screen position of dot *)
begin (* dotpos *)
  winprelude(true);
  wupd1;
  if not knownpos then wsetpos;
  row:= vpos+winfirst; col:= hpos;
end (* dotpos *);

  (**** POSDOT ****)
(*@VMS: [global] *)
function posdot(x: integer): bufpos;
label 9;
var pt: bufpos; pos: integer; ch: char;
begin (* posdot *)
  pt:= rrdot; pos:= 0;
  while (pt<rrz) and (pos<x) do begin
    ch:= bgetchar(pt);
    if ch in printable then begin
      pos:= pos+1;
    end else begin
      if ch=chr(HorizontalTab) then begin
	pos:= ((pos+8) div 8) * 8;
      end else if ch=chr(Escape) then begin
	pos:= pos+1;
      end else begin
	pos:= pos+2;
      end;
      if ateol(pt, 1) then goto 9;
      if pos>x then goto 9;	
    end;
    pt:= pt+1;
  end;
9:
  posdot:= pt;
end (* posdot *);

  (**** MODEWRITE ****)
(*@VMS: [global] *)
procedure modewrite(ch: char);
begin
  winprelude(true);
  if (moderow<modeheight-1) and (modecol=screenwidth-1) then begin
    lines[modetop+moderow].updated:= false;
    modelines[moderow][modecol]:= '!';
    moderow:= moderow+1; modecol:= 0;
  end;
  if (moderow<modeheight-1) and (modecol<=screenwidth-1)
  or (moderow=modeheight-1) and (modecol<=screenwidth-pcntwidth-2) then begin
    lines[modetop+moderow].updated:= false;
    modelines[moderow][modecol]:= ch; modecol:= modecol+1;
  end;
end (* modewrite *);

(*---------------------------------------------------------------------------*)
(* ModeArrow writes a character in the mode area. Control characters are     *)
(* written in the uparrow form.						     *)

procedure ModeArrow(c: char);
var
  i: integer;
begin
  if c in printable then begin
    modewrite(c)
  end else begin
    for i := 1 to chrvlen[c]
    do modewrite(chrview[c, i]);
  end;
end;

(*---------------------------------------------------------------------------*)
(* ModeString writes a string in the mode area, followed by one space.	     *)

(*@VMS: [global] *)
procedure ModeString(Str: string);
var
  pos: integer;
begin
  for pos := 1 to StrLength(Str)
  do ModeArrow(Str[pos]);
  modewrite(' ');
end;

  (**** MODEPOS ****)
(*@VMS: [global] *)
procedure modepos(row, col: integer);
begin
  moderow:= row; modecol:= col;
end (* modepos *);

  (**** MODEWHERE ****)
(*@VMS: [global] *)
procedure modewhere(var row, col: integer);
begin
  row:= moderow; col:= modecol;
end (* modewhere *);

  (**** MODESIZE ****)
(*@VMS: [global] *)
procedure modesize(var height, width: integer);
begin
  height:= modeheight; width:= screenwidth;
end (* modesize *);

  (**** MODECLEAR ****)
(*@VMS: [global] *)
procedure modeclear;
var row, col: integer;
begin
  winprelude(true);
  for row:= modetop to modetop+modeheight-1 do lines[row].updated:= false;
  for row:= 0 to modeheight-2 do modelines[row]:= blanktext;
  for col:= 0 to screenwidth-10-1 do modelines[modeheight-1][col]:= ' ';
  moderow:= 0; modecol:= 0;
  ClockIsOn:= false;		(* The clock is off now. *)
end (* modeclear *);

  (**** TimeOut ****)
(*@VMS: [global] *)
procedure TimeOut(Hours, Minutes: integer);
begin
  modewrite(chr((Hours div 10) + ord('0')));
  modewrite(chr((Hours mod 10) + ord('0')));
  modewrite(':');
  modewrite(chr((Minutes div 10) + ord('0')));
  modewrite(chr((Minutes mod 10) + ord('0')));
end (* TimeOut *);

  (**** TIMESTAMP ****)
(*@VMS: [global] *)
procedure TimeStamp;
var
  MRow, MCol: integer;
  TRow, TCol: integer;
  Hour, Minute: integer;
  Void: boolean;
begin
  if ClockIsOn then begin	(* Only update if the clock is on *)
    TrmWhere(TRow, TCol);	(* Get position on physical screen *)
    modewhere(MRow, MCol);	(* Save mode line position *)
    GetClock(Hour, Minute);	(* Get current time *)
    if Minute = 0		(* Even hour? *)
    then begin
      modepos(ClockRow, ClockCol); (* Go to clock field *)
      modewrite('P');
      modewrite('l');
      modewrite('i');
      modewrite('n');
      modewrite('g');
      UpdModeLines;		(* Update the mode line *)
      ttyforce;			(* Force all output *)
      Void := check(1);		(* Wait a second. *)
    end;
    modepos(ClockRow, ClockCol); (* Go to clock field *)
    TimeOut(Hour, Minute);	(* Put new time in mode line *)
    modepos(MRow, MCol);	(* Restore old mode line pos *)
    UpdModeLines;		(* Update the mode line *)
    trmpos(TRow, TCol);		(* Restore physical position *)
    ttyforce;			(* Force out all buffers *)
  end;
end (* TimeStamp *);

  (**** MODETIME ****)
(*@VMS: [global] *)
procedure ModeTime;
var
  Hour, Minute: integer;
begin
  ClockIsOn:= true;		(* The clock just got turned on... *)
  ClockRow := moderow;
  ClockCol := modecol;
  GetClock(Hour, Minute);
  TimeOut(Hour, Minute);	(* Get the clock going... *)
end (* ModeTime *);

  (**** ECHOUPDATE ****)
(*@VMS: [global] *)
procedure echoupdate;
var row: integer;
begin
  simplep:= false;
  if not kbdrunning then begin
    for row:= echotop to echotop+echoheight-1 do
    if not lines[row].updated then updateline(row, echolines[row-echotop]);
    trmpos(echotop+echorow, echocol); ttyforce;
  end;
end (* echoupdate *);

  (**** ECHOEOL ****)
(*@VMS: [global] *)
procedure echoeol;
var col: integer;
begin
  winprelude(true);
  lines[echotop+echorow].updated:= false;
  for col:= echocol to screenwidth-1 do echolines[echorow][col]:= ' ';
end (* echoeol *);

  (**** ECHOWRITE ****)
(*@VMS: [global] *)
procedure echowrite(ch: char);
begin
  winprelude(true);
  if (echorow<echoheight-1) and (echocol=screenwidth-1) then begin
    lines[echotop+echorow].updated:=false;
    echolines[echorow][echocol]:= '!';
    echorow:= echorow+1; echocol:= 0;
  end;
  if (echorow<echoheight) and (echocol<=screenwidth-1) then begin
    lines[echotop+echorow].updated:= false;
    if (echorow=echoheight-1) and (echocol>=screenwidth-2) then begin
      echocol:= 0; echoeol;
    end;
    echolines[echorow][echocol]:= ch; echocol:= echocol+1;
  end;
end (* echowrite *);

(*@VMS: [global] *)
procedure echopos(row, col: integer);
begin
  echorow:= row; echocol:= col;
end (* echopos *);

  (**** ECHOWHERE ****)
(*@VMS: [global] *)
procedure echowhere(var row, col: integer);
begin
  row:= echorow; col:= echocol;
end (* echowhere *);

  (**** ECHOSIZE ****)
(*@VMS: [global] *)
procedure echosize(var height, width: integer);
begin
  height:= echoheight; width:= screenwidth;
end (* echosize *);

(*---------------------------------------------------------------------------*)
(* EchoArrow writes a character in the echo area. Control characters are     *)
(* written in the uparrow form.						     *)

(*@VMS: [global] *)
procedure EchoArrow(c: char);
var
  i: integer;
begin
  if c in printable then begin
    echowrite(c)
  end else begin
    for i := 1 to chrvlen[c]
    do echowrite(chrview[c, i]);
  end;
end;

(*---------------------------------------------------------------------------*)
(* EchoString writes a string in the echo area, followed by one space.	     *)

(*@VMS: [global] *)
procedure EchoString(Str: string);
var
  pos: integer;
begin
  for pos := 1 to StrLength(Str)
  do EchoArrow(Str[pos]);
  echowrite(' ');
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure WinFlags(flags: string);
var c: char;
begin
  c := flags[3];		(* "Display line feed as EOL" *)
  if c = '+' then EolLineFeed := true;
  if c = '-' then EolLineFeed := false;
  c := flags[4];		(* "Display Escape as $" *)
  if c = '+' then begin
    chrview[chr(Escape)] := '$   ';
    chrvlen[chr(Escape)] := 1;
  end;
  if c = '-' then begin
    chrview[chr(Escape)] := '^[  ';
    chrvlen[chr(Escape)] := 2;
  end;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure scrinit(total: boolean);
var
  i: integer;
  eol: string;
begin (* wininit *)
  for i:= 0 to maxwidth do begin
    blanktext[i]:= ' '; messedtext[i]:= chr(RubOut);
  end;
  (* Initialize terminal dependent variables *)
  TrmSize(screenheight, screenwidth);
  TrmFeatures(xyflag, eolflag, scrflag);
  TrmPrintable(printable);
  for i := 0 to 31 do begin
    chrview[chr(i)][1] := '^';
    chrview[chr(i)][2] := chr(i + 64);
    chrvlen[chr(i)] := 2;
  end;
 (*@TOPS: chrview[chr(Escape)] := '$   '; *)
 (*@TOPS: chrvlen[chr(Escape)] := 1; *)
  for i := 32 to 126 do begin
    chrview[chr(i)][1] := chr(i);
    chrvlen[chr(i)] := 1;
  end;
  chrview[chr(127)] := '^?  ';
  chrvlen[chr(127)] := 2;
 (*@VMS:
  for i := 128 to 255 do begin
    chrview[chr(i)] := '^*  ';
    chrvlen[chr(i)] := 2;
  end;
 *) (* Done simple VMS set-up. *)
  if screenheight > maxheight then screenheight := maxheight;
  if screenwidth > maxwidth then screenwidth := maxwidth;
  if screenwidth>40 then echoheight:= 1 else echoheight:= 2;
  echotop:= screenheight-echoheight;
  echorow:=0; echocol:= 0;
  for i:= 0 to echoheight-1 do echolines[i]:= blanktext;
  if screenwidth>40 then modeheight:= 1 else modeheight:= 2;
  modetop:= echotop-modeheight;
  moderow:= 0; modecol:= 0;
  for i:= 0 to modeheight-1 do modelines[i]:= blanktext;
  ClockIsOn:= false;		(* The clock is not yet on *)
  winheight:= modetop;
  winfirst:= 0; winlast:= winheight-1;
  if total then begin
    splitline:= winheight div 2;
    nwins:= 1; curwin:= 1;
  end else begin
    wingrow(0);
  end;
  linecost:= 20; trmcst(scrollcost, idcharcost);
  (* Say complete update necessary *)
  if total then begin
    rrdot:= 0; rrz:= 0;
  end;
  first:= 0; last:= rrz; count:= rrz;
  csflg:= true;
  noprelude:= false;
  if total then begin
    built:= nopos;
    winstart:= 0; winend:= 0;
    xwinstart[1]:= 0; xwinend[1]:= 0;
    xwinstart[2]:= 0; xwinend[2]:= 0;
    curbuffer[1]:= 1; curbuffer[2]:= 0;
    showbuffer[1]:= 1; showbuffer[2]:= 0;
  end else begin
    if built=ok then built:= pos;
    xok[1]:= false; xok[2]:= false;
  end;
  new_buffer:= curbuffer[curwin]; new_window:= curwin;
  hpos:= 0; vpos:= 0; knownpos:= false;
  simplep:= false; scount:= 0; spos:= 0;
  ovmode:= false; ovflush:= false; orow:= 0;
  EolString(eol, i);
  EolFirst := eol[1];
  EolLineFeed := false;
end; (* scrinit *)

(*---------------------------------------------------------------------------*)

(*@TOPS: begin end. *)
(*@VMS: end. *)
