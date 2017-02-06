(* AMIS terminal driver. *)	(* -*- PASCAL -*- *)

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

(*$E+,T-,S3000 *)

(****************************************************************)
(*								*)
(*		1980-09-21 Birth of AMIS			*)
(*								*)
(****************************************************************)

module term;

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

  strsize	= 40;		(* Length of a string in AMIS *)

(*@VMS:  DskSize = 512; *)	(* number of chars in a disk block *)
(*@TOPS: DskSize = 640; *)

  dskwarning    = -1;		(* Error code for not found or end of file *)
  dskerror      = -2;		(* Other strange disk errors *)

  dsk_init_file = 1;		(* Internal number for user init file *)
  sys_init_file = 2;		(* Internal number for system init file *)

type
  
  string = packed array [1..strsize] of char;

  charset = set of char;

  sixbytes = packed array[1..6] of char;

  long_string = record
                  len: integer;
		  c: packed array [1..40] of char;
		end;

  cop = record 
             len: integer;
	     c: array[1..10] of char;
           end;

  actions = (up,down,left,right,eol,home,dca,tab,clear,idchar,idline,hilite);

  features = set of actions;

  dskblock = packed array [1..dsksize] of char;

  dskbp = ^dskblock;

var
  name		: sixbytes;	(* Terminal name *)

  c_up		: cop;		(* Cursor up. *)
  c_down	: cop;		(* Cursor down. *)
  c_left	: cop;		(* Cursor left. *)
  c_right	: cop;		(* Cursor right. *)
  c_home	: cop;		(* Cursor home. *)

  e_screen	: cop;		(* Erase screen. *)
  e_scr_ft	: integer;	(* Fill time for above. *)
  e_eol		: cop;		(* Erase to end of current line. *)
  e_eol_ft	: integer;	(* Fill time for above. *)

  ic_on		: cop;		(* Insert character mode on/off *)
  ic_off	: cop;
  dc		: cop;		(* Delete character function *)
  idch_ft	: integer;
  idln_ft	: integer;

  hi_on		: cop;		(* High-light mode on/off *)
  hi_off	: cop;

  visibell	: cop;		(* non-^G beep. *)

  e_eol_fc	: integer;	(* Number of fillers to send for *)
  e_scr_fc	: integer;	(* different operations. *)
  idch_fc	: integer;
  idln_fc	: integer;

  xpos		: integer;	(* Current cursor position *)
  ypos		: integer;
  cursor	: boolean;	(* True if known the cursor position *)

  hastab	: boolean;	(* local feature flags *)
  hasdca	: boolean;

  lines		: integer;	(* Physical size of video screen *)
  width		: integer;
  wrap		: boolean;
  unknown	: boolean;	(* Known wrap behavour? *)

  UseReturn	: boolean;	(* Can we use CR to go to left margin? *)

  Feat		: features;
  FillCharacter	: char;

(* Behaviourism: *)

  BeepStyle	: char;		(* 'A', 'N', or 'V'. *)

(*  Initialization and deactivation strings.  *)

  InitString	: long_string;
  ExitString	: long_string;

(*  DCA control variables.  *)

  DcaLeadIn	: cop;
  DcaInter	: cop;
  DcaTrailing	: cop;
  decflag	: boolean;	(* DCA addresses in decimal? *)
  colfirst	: boolean;
  rownegate	: boolean;
  colnegate	: boolean;
  exrange	: boolean;	(* Are there column exceptions? *)
  rowoffset	: integer;
  coloffset	: integer;
  cxbegin	: integer;
  cxend		: integer;
  cxoffset	: integer;

(*  Region scroll control variables.  *)

  VT100Scroll	: boolean;	(* VT100 region scroll useable? *)
  ILBegin	: cop;
  ILEnd		: cop;
  DLBegin	: cop;
  DLEnd		: cop;
  IDLmulti	: boolean;
  IDLdecimal	: boolean;
  IDLoffset	: integer;

(* External procedures called from TERM *)
(* terminal routines from module TTYIO *)

procedure GetFSpec(var FileName: string; FileNumber: integer); external;
procedure SaveTerminalName(name: sixbytes); external;
procedure BadTTY; external;
PROCEDURE bug (bugstr: string); external;
PROCEDURE ttywrite (ch: char); external;
procedure TTyForce; external;
FUNCTION ttytype(var t: sixbytes): boolean; external;
FUNCTION ttywidth: integer; external;
procedure TtyLength(var l: integer); external;
FUNCTION ttyspeed: integer; external;
function TTyEight: boolean; external;
procedure TtyPrintable(var Printable: charset); external;
PROCEDURE ttyactivation (var is,es: long_string); external;
PROCEDURE monitor; external;

  (* File handling functions from DSKIO *)

function DskOpen(FileName: string; Access: char): integer; external;
function DskRead(var p: dskbp): integer; external;
function DskClose: integer; external;

  (* Utility routines from UTILITY *)

PROCEDURE putdec (var t: string; val,pos,size: integer); external;

  (* Needed forward declarations ..*)

(*@VMS: [global] *)
PROCEDURE trmpos (row,col: integer); forward;

  (* Local routines *)

PROCEDURE SendCursorOp (var s: cop);	(* Send a cursor control *)
var						(* string to terminal *)
  i: integer;
begin
  with s do for i := 1 to len do ttywrite (c[i]);
end;

procedure fill(n: integer);	(* Send "n" fillers *)
var i: integer;
begin
  for i := 1 to n do ttywrite(FillCharacter);
end;

procedure outcoord (n: integer);		(* Prints integer *)
begin
    if n>9 then begin				(* if more than one digit *)
      outcoord (n div 10);			(* recursive call *)
    end;
    ttywrite (chr((n mod 10)+ord('0')))		(* write a digit *)
end;  (* of outcoord *)

procedure trmhome;				(* Set cursor at home pos *)
begin
  SendCursorOp(c_home);
  xpos := 0; ypos := 0;
  cursor := true
end;

PROCEDURE trmup (n: integer);			(* Move cursor up *)
var
  i: integer;
begin
  if n>0 then begin
    ypos := ypos-n;
    if ypos >= 0 then begin
      for i:=1 to n do SendCursorOp (c_up);
    end
    else cursor := false;
  end;
end;

PROCEDURE trmdown (n: integer);			(* Move cursor down *)
var
  i: integer;
begin
  if n > 0 then begin
    ypos := ypos+n;
    if ypos < lines then begin
      for i:=1 to n do SendCursorOp (c_down);
    end
    else cursor := false;
  end;
end;

PROCEDURE trmright (n: integer);		(* Move cursor forward *)
var
  i: integer;
begin
  if n>0 then begin
    xpos := xpos+n;
    if xpos < width then begin
      for i:=1 to n do SendCursorOp (c_right);
    end
    else cursor := false;
  end;
end;

PROCEDURE trmleft (n: integer);			(* Move cursor backward *)
var
  i: integer;
begin
  if n > 0 then begin
    xpos := xpos-n;
    if xpos >= 0 then begin
      for i:=1 to n do SendCursorOp (c_left);
    end
    else cursor := false;
  end;
end;

procedure SetDefaultTerminal;
begin
  with c_up do begin
    c[1] := chr(escape);
    c[2] := '[';
    c[3] := 'A';
    len := 3
  end;
  with c_down do begin
    c[1] := chr(linefeed);
    len := 1;
  end;
  with c_left do begin
    c[1] := chr(ctrlH);
    len := 1;
  end;
  with c_right do begin
    c[1] := chr(escape);
    c[2] := '[';
    c[3] := 'C';
    len := 3;
  end;
  with c_home do begin
    c[1] := chr(escape);
    c[2] := '[';
    c[3] := 'H';
    len := 3;
  end;
  with e_eol do begin
    c[1] := chr(escape);
    c[2] := '[';
    c[3] := 'K';
    len := 3;
  end;
  with e_screen do begin
    c[1] := chr(escape);
    c[2] := '[';
    c[3] := 'H';
    c[4] := chr(escape);
    c[5] := '[';
    c[6] := 'J';
    len := 6;
  end;
  e_scr_ft := 100;
  with DcaLeadIn do begin
    c[1] := chr(escape);
    c[2] := '[';
    len := 2;
  end;
  with DcaInter do begin
    c[1] := ';';
    len := 1;
  end;
  with DcaTrailing do begin
    c[1] := 'H';
    len := 1;
  end;
  decflag := true;
  colfirst := false;
  rownegate := false;
  colnegate := false;
  exrange := false;
  rowoffset := 1;
  coloffset := 1;
  InitString.len := 0;
  ExitString.len := 0;
  ic_on.len := 0;
  ic_off.len := 0;
  dc.len := 0;
  width := 80;
  lines := 24;
  FillCharacter := chr(rubout);
  UseReturn := true;
  Feat := [up,down,left,right,eol,home,dca,clear];
  wrap := false;
  unknown := true;
end;

PROCEDURE settermdescr;				(* Set all terminal dependant*)
var						(* variables in the t_descr. *)
  t_name: sixbytes;
  n: integer;
  found: boolean;
  dskcode: integer;
  endfile: boolean;
  bufsize: integer;
  diskbuffer: dskbp;
  index: integer;
  baudrate: integer;
  default: boolean;

  PROCEDURE parse;		(* this proc parses one disk block of *)
  var				(* ASCII characters into a terminal descr *)
    i: integer;			(* The correct format is generated by the *)
    c: char;			(* MAKTRM program *)
    dummy: cop;
    dcaalg: integer;
    scralg: integer;

    FUNCTION getchar: char;	(* This function returns the next character *)
    label 9;
    begin			(* from the disk buffer *)
      if not endfile then begin
        if bufsize = 0 then begin		(* check if empty buffer *)
	  dskcode := dskread (diskbuffer);
	  if dskcode = dskerror			(* Read error *)
	  then bug('TERM: Disk read error in AMIS.TRM       ');
	  if dskcode <= 0 then begin
	    endfile := true;			(* end of file reached *)
	    getchar := ' ';			(* return a space *)
	    goto 9;				(* exit from procedure *)
	  end;
	  bufsize := dskcode;			(* Set new buffer size *)
	  index := 1;
	end;
	getchar := diskbuffer^[index];		(* return next character *)
	index := index + 1; bufsize := bufsize - 1;
      end
      else getchar := ' ';
    9:
    end;
  
    FUNCTION getint (len: integer): integer;	(* Read an integer that *)
    var						(* consists of len digits *)
      n,i: integer;
    begin
      n := 0;
      for i:=1 to len do n := 10 * n + (ord(getchar) - ord('0'));
      getint := n;
    end;
  
    PROCEDURE get_cop (var t: cop);
    var					(* fill a record of type cop *)
      i: integer;			(* with data from the disk block *)
    begin
      with t do begin
        len := getint (2);
        for i:=1 to len do c[i] := getchar;
      end;
    end;
  
    PROCEDURE get_long_string (var ls: long_string);
    var					(* fill a long_string with characters*)
      i: integer;
    begin
      with ls do begin
        len := getint (2);
        for i:=1 to len do c[i] := getchar;
      end;
    end;

    procedure getf(a: actions);
    begin
      if getchar = '1' then Feat := Feat + [a];
    end;

    procedure getflag(var b: boolean);
    begin
      b := (getchar = '1');
    end;

  begin  (* Parse *)
    for i:=1 to 6 do name[i] := getchar;	(* this is the name *)
    if not endfile then begin
      SaveTerminalName(name);
      get_cop (c_up);
      get_cop (c_down);
      get_cop (c_left);
      get_cop (c_right);
      get_cop (c_home);
      get_cop (e_eol);
      e_eol_ft := getint (4);
      get_cop (e_screen);
      e_scr_ft := getint (4);
      get_cop (dummy);
      dcaalg := getint (2);
      get_cop (ic_on);
      get_cop (ic_off);
      get_cop (dc);
      idch_ft := getint (4);
      get_cop (dummy); (* ins_line *)
      get_cop (dummy); (* del_line *)
      idln_ft := getint (4);
      scralg := getint (2);
      get_cop (hi_on);
      get_cop (hi_off);
      get_long_string (InitString);
      get_long_string (ExitString);
      Feat := [];
      getf(up);
      getf(down);
      getf(left);
      getf(right);
      getf(eol);
      getf(home);
      getf(dca);
      getf(tab);
      getf(clear);
      getf(idchar);
      getf(idline);
      getf(hilite);
      width := getint (3);
      lines := getint (2);
      c := getchar;
      unknown := c = 'U';
      wrap := c = 'T';
      FillCharacter := chr(getint (3));
      UseReturn := false;	(* Just to be sure... *)
      if (dca in Feat) and (dcaalg = 0)
      then begin
	get_cop(DcaLeadIn);
	get_cop(DcaInter);
	get_cop(DcaTrailing);
	getflag(decflag);
	getflag(colfirst);
	getflag(rownegate);
	getflag(colnegate);
	getflag(exrange);
	getflag(UseReturn);
	rowoffset := getint(3);
	coloffset := getint(3);
	cxbegin := getint(3);
	cxend := getint(3);
	cxoffset := getint(3);
	c := getchar;
      end;
      if (idline in Feat) and (scralg = 0)
      then begin
	getflag(VT100Scroll);
	get_cop(ILBegin);
	get_cop(ILEnd);
	get_cop(DLBegin);
	get_cop(DLEnd);
	getflag(IDLmulti);
	getflag(IDLdecimal);
	IDLoffset := getint(3);
	c := getchar;
      end;
      if dcaalg <> 0 then Feat := Feat - [dca];
      if scralg <> 0 then Feat := Feat - [idline]
    end;
    c := getchar; c := getchar;		(* skip CRLF between recs *)
  end;

  procedure ParseFile(Number: integer);
  var
    FileName: string;
  begin (* ParseFile *)
    GetFSpec(FileName, Number);	(* Translate file number to name *)
    DskCode := DskOpen(FileName, 'R');
    Found := false;		(* Indicate not found type *)
    if DskCode = 0 then begin	(* open succeded *)
      BufSize := 0;		(* Buffer is empty *)
      EndFile := false;		(* we have not seen end file *)
      repeat
	Parse;
	Found := name = t_name;
      until Found or EndFile;
      DskCode := DskClose;	(* Close file *)
    end;
  end; (* ParseFile *)

begin (* SetTermDescr *)
  default := ttytype(t_name);	(* get terminal model from monitor *)
  ParseFile(Dsk_Init_File);
  if not Found then ParseFile(Sys_Init_File);
  if not Found then begin
    if default			(* Last chance: VT100 is built-in *)
    then SetDefaultTerminal
    else Badtty;		(* We did not find it *)
  end;
  TtyLength(lines);		(* Select length from OS, or use default. *)
  n := ttywidth;		(* get logical line length *)
  if n <> width then begin	(* check if smaller than physical *)
    width := n;			(* Use logical length anyway *)
    wrap := false;		(* this will make this work *)
  end;
  TtyActivation(InitString, ExitString); (* Setup init and exit strings *)

  baudrate := ttyspeed;		(* Get baud rate from monitor *)
  e_eol_fc := (e_eol_ft * baudrate + 9999) div 10000;
  e_scr_fc := (e_scr_ft * baudrate + 9999) div 10000;
  idch_fc := (idch_ft * baudrate + 9999) div 10000;
  idln_fc := (idln_ft * baudrate + 9999) div 10000;
end;  (* of Set_term_descr *)

procedure DcaCoord(i: integer);
begin
  if decflag
  then outcoord(i)
  else ttywrite(chr(i MOD 128));
end;

procedure XXXDCA(row, col: integer);
var
  r, c	: integer;
begin
  if rownegate
  then r := rowoffset - row
  else r := rowoffset + row;
  c := coloffset;
  if exrange then begin
    if (col >= cxbegin) and (col <= cxend)
    then c := cxoffset;
  end;
  if colnegate
  then c := c - col
  else c := c + col;
  SendCursorOp(DcaLeadIn);
  if colfirst then DcaCoord(c) else DcaCoord(r);
  SendCursorOp(DcaInter);
  if colfirst then DcaCoord(r) else DcaCoord(c);
  SendCursorOp(DcaTrailing);
end;

procedure stupid(row,col: integer);
begin
  if abs(row-ypos)>row then trmhome;
  if row>ypos then
    trmdown (row-ypos)
  else
    trmup (ypos-row);
  if (abs(col-xpos))>col then
    if xpos<>0 then begin
      ttywrite (chr(carriagereturn)); xpos := 0
    end;
  while xpos<>col do
    if col>xpos then
      if (xpos+8-(xpos mod 8)<=col) and hastab then begin
	ttywrite (chr(ctrlI)); xpos := xpos+8-(xpos mod 8);
      end
      else
	trmright (col-xpos)
    else
      trmleft (xpos-col);
end;  (* of STUPID *)

procedure SetCursor(row,col: integer);		(* Position the cursor *)
begin
  if not hasdca
  then stupid(row, col)
  else begin
    XXXDCA(row, col);
    xpos := col;
    ypos := row;
    cursor := true;
  end;
end;

procedure IDLarg(k: integer);
begin
  if IDLdecimal
  then outcoord(k + IDLoffset)
  else ttywrite(chr((k + IDLoffset) MOD 128));
end;

procedure inslines (n, k: integer);	(* Insert k lines at pos n *)
var
  i: integer;
begin
  trmpos(n,0);					(* position the cursor *)
  if IDLmulti then begin
    SendCursorOp(ILBegin);
    IDLarg(k);
    SendCursorOp(ILEnd);
    Fill(k * idln_fc);
  end else for i := 1 to k do begin
    SendCursorOp(ILBegin);
    Fill(idln_fc);
  end;
  cursor := false;
end; (* of INSLINES *)

procedure dellines (n, k: integer);	(* Delete k lines at pos n *)
var
  i: integer;
begin
  trmpos(n,0);					(* position the cursor *)
  if IDLmulti then begin
    SendCursorOp(DLBegin);
    IDLarg(k);
    SendCursorOp(DLEnd);
    Fill(k * idln_fc);
  end else for i := 1 to k do begin
    SendCursorOp(DLBegin);
    Fill(idln_fc);
  end;
  cursor := false;
end; (* of DELLINES *)

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure trmsize(var row, col: integer);
begin
  row := lines;
  col := width;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure trmclr;
begin
  SendCursorOp(e_screen);
  xpos := 0;
  ypos := 0;
  cursor := true;
  fill(e_scr_fc);
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure trmeol;
begin
  SendCursorOp(e_eol);
  fill(e_eol_fc);
end;

(*---------------------------------------------------------------------------*)

procedure trmpos;
label 17;
var errmsg: string;
begin
  if (row<0) or (row>=lines) or (col<0) or (col>=width) then begin
    errmsg := 'TERM: TrmPos Row,Col=   ,               ';
    putdec (errmsg,row,22,3);
    putdec (errmsg,col,26,3);
    bug (errmsg)
  end;
  if not cursor then begin
    if not hasdca then trmhome;
    SetCursor(row,col); goto 17;
  end;
  if (row=ypos) and (col=xpos) then goto 17;
  if col = 0 then begin
    if row = 0 then begin
      trmhome;
      goto 17
    end;
    if UseReturn then begin
      if row=ypos+1 then begin
	ttywrite (chr(carriagereturn)); trmdown (1);
	ypos := row; xpos := 0;
	goto 17;
      end;
      if row=ypos then begin
	ttywrite (chr(carriagereturn)); xpos := 0;
	goto 17
      end;
    end; (* Use Return *)
  end; (* col = 0 *)
  if abs(row-ypos)+abs(col-xpos)<2 then begin
    if col>xpos then
      trmright (col-xpos)
    else
      trmleft (xpos-col);
    if row>ypos then
      trmdown (row-ypos)
    else
      trmup (ypos-row);
    goto 17
  end;
  SetCursor(row,col);
  17:
end; (* TrmPos *)

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure TrmWhere(var row, col: integer);
begin
  row := ypos;
  col := xpos;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure TrmBeep;
begin
  if (BeepStyle = 'A') or ((BeepStyle = 'V') and (visibell.len = 0))
  then begin
    TTyWrite(Chr(Bell));
    TTyForce;
  end;
  if (BeepStyle = 'V') and (visibell.len > 0)
  then begin
    SendCursorOp(visibell);
    TTyForce;
  end;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure trmout(c: char);
begin
  ttywrite(c);
  xpos := xpos+1;
  if xpos=width then begin
    xpos := 0;
    ypos := ypos+1;
    if not wrap then begin
      if unknown then begin
	Cursor := false;
	TrmPos(ypos,xpos);
      end else begin
	ttywrite(chr(carriagereturn));
	ttywrite(chr(linefeed))
      end;
    end;
  end;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure trmich(c: char); (* Insert a character *)
begin
  SendCursorOp(ic_on);
  trmout(c);
  SendCursorOp(ic_off);
  fill(idch_fc);
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure trmdch;	(* Delete a character *)
begin
  SendCursorOp(dc);
  fill(idch_fc);
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure TrmFreeze;
begin
  if VT100Scroll then begin	(* Is this a VT100 or equiv? *)
    ttywrite(chr(escape)); ttywrite('[');
    ttywrite('1'); ttywrite('3'); ttywrite(';');
    ttywrite('2'); ttywrite('4'); ttywrite('r');
    cursor := false;
    trmpos(ypos, xpos);
  end;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure trmscr(first,last,n: integer);
var
  k: integer;
  errmes: string;
begin
  if (first<0) or (last>=lines) or (abs(n)>last-first+1) then begin
    errmes := 'TERM: TrmScr Y1,Y2,N=   ,   ,           ';
    putdec (errmes,first,22,3);
    putdec (errmes,last,26,3);
    putdec (errmes,n,30,3);
    bug (errmes)
  end;
  if VT100Scroll then begin
    TtyWrite(chr(escape)); TtyWrite('[');
    if first>0 then outcoord (first+1);	(* Top margin *)
    ttywrite (';');
    outcoord (last+1);			(* Bottom margin *)
    ttywrite ('r');
    xpos := 0; ypos := 0;
    cursor := true;
    if n<0 then begin			(* Scroll down *)
      trmpos (first,0);
      for k:= -1 downto n do begin
	ttywrite (chr(escape)); ttywrite ('M');
	fill(idln_fc);
      end;
    end;
    if n>0 then begin		(* Scroll up *)
      trmpos (last,0);
      for k:= 1 to n do begin
	ttywrite (chr(escape)); ttywrite ('D');
	fill(idln_fc);
      end;
    end;
    ttywrite(chr(escape)); ttywrite('['); (* Restore margins *)
    ttywrite('r');
    xpos := 0; ypos := 0;
    cursor := true;
  end else begin
    if n < 0 then begin
      DelLines(last + n + 1, -n);
      InsLines(first, -n);
    end;
    if n > 0 then begin
      DelLines(first, n);
      InsLines(last - n + 1, n);
    end;
  end;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure trmfeatures(var xyflag, eolflag, scrflag: boolean);
begin
  xyflag := hasdca;
  eolflag := eol in feat;
  scrflag := idline in feat;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure TrmPrintable(var Printable: charset);
begin
  TTyPrintable(printable);
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure trminv;		(* Inverse video *)
begin
  SendCursorOp(hi_on);
end;

(*@VMS: [global] *)
procedure trmniv;		(* Normal video *)
begin
  SendCursorOp(hi_off);
end;

(*---------------------------------------------------------------------------*)

(* Give terminalspecific estimate of cost for doing scroll *)
(* or character insert/delete. Cost is number of outputted *)
(* characters. *)

(*@VMS: [global] *)
procedure trmcst(var scrollcost, idcharcost: integer);
begin
  scrollcost := 4 + 2 * idln_fc;
  idcharcost := 4 + idch_fc;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure TrmFlags(flags: string);
var c: char;
begin
  c := flags[9];                (* "Beep Style" *)
  if c in ['A', 'N', 'V'] then BeepStyle := c;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure TrmInit;
begin				(* Called by MAIN on start *)
  SetTermDescr;			(* Load term descriptor *)
  hastab := tab in Feat;	(* Get us some info locally *)
  hasdca := dca in Feat;
  xpos := 0;			(* Reset internal positions to *)
  ypos := 0;			(* Something sensible *)
  cursor := false;		(* We dont know where the cursor is *)
  BeepStyle := 'A';		(* Normally we beep user. *)
  visibell.len := 0;		(* Until... *)
end;

(*---------------------------------------------------------------------------*)

(*@TOPS: begin end. *)
(*@VMS: end. *)
