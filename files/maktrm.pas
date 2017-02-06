program MakTrm;

label 9;

const
  strsize = 40;
  tab = 9;
  rubout = 127;
  nfeatures = 50;

type
  string = packed array[1..strsize] of char;

  fttype = (cursorop,number,yesno,tristate,termname);

  ft = record
    tag		: string;
    size	: integer;
    text	: string;
    syntax	: fttype;
    synonyme	: integer;
  end;

var
  infile	: file of char;
  outfile	: file of char;
  c		: char;
  more		: Boolean;
  tagbuf	: string;
  taglength	: integer;
  j		: integer;
  feature	: array[1..nfeatures] of ft;
  newterm	: Boolean;
  atombuf	: string;
  atomlength	: integer;
  newdcaflag	: boolean;
  newscrflag	: boolean;
  exceptions	: boolean;

function rdline(var answ: string): integer;
var i,j: integer; buf: string;
begin
  i:=0;
  readln(tty, buf:i);
  if buf<>'                                        ' then answ:=buf;
  rdline:=i
end;

procedure warn(msg: string);
begin
  writeln(tty,msg);
  writeln(tty,' (tag = "', tagbuf:taglength, '")');
end;

procedure error(msg: string);
begin
  warn(msg);
  goto 9
end;

procedure eat1;
begin
  if eof(infile) or eoln(infile) then
    more:=false
  else begin
    c:=infile^;
    get(infile);
    more:=true
  end
end;

function upcase(c: char): char;
begin
  if (97<=ord(c)) and (ord(c)<=122)
  then upcase:=chr(ord(c)-32)
  else upcase:=c
end;

function spaceortab(c: char): Boolean;
begin
  spaceortab:= (c=' ') or (c=chr(tab))
end;

procedure skipblanks;
begin
  while more and spaceortab(c) do eat1
end;

function striptail(buf: string; i: integer): integer;
var j: integer; f: Boolean;
begin
  j:=i; f:=false;
  repeat
    if j<=0 then f:=true
    else if not spaceortab(buf[j]) then f:=true
    else j:=j-1
  until f;
  striptail:=j
end;

procedure getnewline;
begin
  while more do eat1;
  if not eof(infile) then begin
    readln(infile);
    more:=true
  end
end;

function uptocolon: Boolean;
var i: integer;
begin
  eat1;
  skipblanks;
  while more and (c=';') do begin
    getnewline;
    eat1;
    skipblanks
  end;
  i:=0;
  while more and (c<>':') and (i<strsize) do begin
    i:=i+1;
    tagbuf[i]:=c;
    eat1
  end;
  taglength:=striptail(tagbuf,i);
  uptocolon:=(c=':')
end;

function strcomp(s1,s2: string; s1len: integer; s2end: char): Boolean;
var f: Boolean; i: integer;
begin
  i:=1;
  f:=(i<=s1len) and (s2[1]<>s2end);
  while f and (i<=s1len) and (s2[i]<>s2end) do begin
    if s2[i]<>upcase(s1[i]) then f:=false
    else i:=i+1
  end;
  strcomp:=f
end;

function digitp(base: integer; c: char): Boolean;
begin
  if base<=10 then digitp:=('0'<=c) and (c<chr(ord('0')+base))
  else if base<=16 then
    digitp:=(('0'<=c) and (c<='9')) or
	     (('A'<=c) and (c<chr(ord('A')+base-10)))
end;

function getnumber(base: integer): integer;
var n,d: integer;
begin
  n:=0;
  c:=upcase(c);
  while more and digitp(base,c) do begin
    d:=ord(c)-ord('0');
    if (base>10) and (d>9) then d:=d-(ord('A')-ord('9')-1);
    n:=base*n+d;
    eat1;
    c:=upcase(c)
  end;
  getnumber:=n
end;

procedure putchar(c: char);
begin
  outfile^:=c; put(outfile)
end;

procedure putnum1(n, digits: integer);
begin
  if digits>0 then begin
    putnum1(n div 10, digits-1);
    putchar(chr(ord('0')+(n mod 10)));
  end
end;

procedure putnumber(i, digits: integer);
begin
  putnum1(feature[i].size, digits)
end;

procedure putbit(b: Boolean);
begin
  if b then putchar('1') else putchar('0')
end;

procedure puttristate(i: integer);
begin
  case i of
    0: putchar('F');		(* NO *)
    1: putchar('T');		(* YES *)
    2: putchar('U');		(* UNKNOWN *)
  end;
end;

procedure putcursorop(i: integer);
var j,n: integer;
begin
  n:=feature[i].size;
  putnum1(n,2);
  for j:=1 to n do putchar(feature[i].text[j])
end;

function lookuptag: integer;
var i: integer; f: Boolean;
begin
  i:=nfeatures; f:=false;
  repeat
    if strcomp(tagbuf,feature[i].tag,taglength,':') then f:=true
    else begin
      i:=i-1;
      if i=0 then f:=true
    end
  until f;
  lookuptag:=i
end;

procedure putterm;
var i,j: integer;
begin
  (* write terminal stuff to outfile *)
  for i:=1 to feature[1].size do putchar(feature[1].text[i]);
  for i:=feature[1].size+1 to 6 do putchar(' ');
  putcursorop(2);
  putcursorop(3);
  putcursorop(4);
  putcursorop(5);
  putcursorop(6);
  putcursorop(7);
  putnumber(8,4);
  putcursorop(9);
  putnumber(10,4);
  putnum1(0,2);			(* Feature 11.  Obsolete. *)
  putnum1(0,2);			(* Feature 12.  Obsolete. *)
  putcursorop(13);
  putcursorop(14);
  putcursorop(15);
  putnumber(16,4);
  putnum1(0,2);			(* Feature 17.  Obsolete. *)
  putnum1(0,2);			(* Feature 18.  Obsolete. *)
  putnumber(19,4);
  putnum1(0,2);			(* Feature 20.  Obsolete. *)
  putcursorop(21);
  putcursorop(22);
  putcursorop(23);
  putcursorop(24);
  putbit(feature[2].size>0);
  putbit(feature[3].size>0);
  putbit(feature[4].size>0);
  putbit(feature[5].size>0);
  putbit(feature[7].size>0);
  putbit(feature[6].size>0);
  putbit(newdcaflag);
  putbit(feature[27].size>0);
  putbit(feature[9].size>0);
  putbit((feature[13].size>0) and (feature[15].size>0));
  putbit(newscrflag);
  putbit((feature[21].size>0) and (feature[22].size>0));
  putnumber(25,3);
  putnumber(26,2);
  puttristate(feature[28].size);
  putnum1(ord(feature[29].text[1]),3);
  if newdcaflag then begin	(* Here we go... *)
    putcursorop(30);		(* DCA Lead in string *)
    putcursorop(31);		(* DCA Intermediate string *)
    putcursorop(32);		(* DCA Trailing string *)
    putbit(feature[33].size>0);	(* DCA Coordinates decimal *)
    putbit(feature[34].size>0);	(* DCA Column first *)
    putbit(feature[35].size>0);	(* DCA Row negate *)
    putbit(feature[36].size>0);	(* DCA Column negate *)
    putbit(exceptions);		(* '1' if column exceptions. *)
    putbit(feature[42].size>0);	(* Use Return to go to left margin. *)
    putnumber(37,3);		(* DCA Row offset *)
    putnumber(38,3);		(* DCA Column offset *)
    putnumber(39,3);		(* DCA Exception begin *)
    putnumber(40,3);		(* DCA Exception end *)
    putnumber(41,3);		(* DCA Exception offset *)
    putchar('0');		(* Extended version number. *)
  end;
  if newscrflag then begin	(* Here we go again... *)
    putbit(feature[43].size>0);	(* VT100 Region Scroll *)
    putcursorop(44);		(* Insert Line Begin *)
    putcursorop(45);		(* Insert Line End *)
    putcursorop(46);		(* Delete Line Begin *)
    putcursorop(47);		(* Delete Line End *)
    putbit(feature[48].size>0);	(* Insert/Delete multiple lines *)
    putbit(feature[49].size>0);	(* I/D Line Argument Decimal *)
    putnumber(50,3);		(* I/D Line Argument Offset *)
    putchar('0');		(* Dummy, for expansion. *)
  end;
  putchar(chr(13)); putchar(chr(10));
end;

function notdelim(c: char): Boolean;
begin
  notdelim:=not(spaceortab(c) or (c=';'))
end;

procedure readatom;
var i: integer;
begin
  i:=0;
  while more and notdelim(c) and (i<strsize) do begin
    i:=i+1;
    atombuf[i]:=upcase(c);
    eat1
  end;
  atomlength:=i
end;

function atomeq(s: string): Boolean;
begin
  atomeq:=strcomp(atombuf,s,atomlength,' ')
end;

procedure clearterm;
var i: integer;
begin
  for i:=1 to nfeatures do feature[i].size:=0;
  feature[25].size := 80;	(* Default terminal width. *)
  feature[26].size := 24;	(* Default terminal length. *)
  feature[28].size := 2;	(* Wrap behavour unknown *)
  feature[29].size := 1;	(* Set default fill char *)
  feature[29].text[1] := chr(rubout);
  feature[42].size := 1;	(* Normally CR goes to left margin. *)
  newdcaflag := false;		(* We have not seen any dca stuff yet. *)
  newscrflag := false;		(* We have not seen any scroll stuff yet. *)
  exceptions := false;		(* Nothing exceptional yet. *)
end;

procedure blankorcomment;
begin
  skipblanks;
  if more then begin
    if not (c=';') then
      warn('%Extra garbage ignored                  ');
    while more do eat1
  end
end;

procedure parseyesno(index: integer);
begin
  skipblanks;
  readatom;
  if atomeq('YES                                     ') then
    feature[index].size:=1
  else if atomeq('NO                                      ') then
    feature[index].size:=0
  else warn('%Value must be YES or NO                ');
  blankorcomment
end;

procedure parsetristate(index: integer);
begin
  SkipBlanks;
  ReadAtom;
  with feature[index] do
  if AtomEq('UNKNOWN                                 ') then size := 2
  else if AtomEq('YES                                     ') then size := 1
  else if AtomEq('NO                                      ') then size := 0
  else warn('%Value must be YES, NO or UNKNOWN       ');
  BlankOrComment;
end;

procedure parsenumber(index: integer);
begin
  skipblanks;
  if digitp(10,c) then
    feature[index].size:=getnumber(10)
  else if c='%' then begin
    eat1;
    feature[index].size:=getnumber(8)
  end
  else if c='#' then begin
    eat1;
    feature[index].size:=getnumber(16)
  end
  else warn('%Illegal syntax for number              ');
  blankorcomment
end;

procedure parsecursorop(index: integer);
var i: integer;
begin
  with feature[index] do begin
    i:=0;
    repeat
      skipblanks;
      if digitp(10,c) then begin
	i:=i+1;
	text[i]:=chr(getnumber(10))
      end
      else if c='%' then begin
	i:=i+1;
	eat1;
	text[i]:=chr(getnumber(8))
      end
      else if c='#' then begin
	i:=i+1;
	eat1;
	text[i]:=chr(getnumber(16))
      end
      else if c='^' then begin
	i:=i+1;
	eat1;
	c:=upcase(c);
	if (ord(c)<64) or (ord(c)>=96) then
	  warn('%Illegal character following "^"        ')
	else
	  text[i]:=chr(ord(upcase(c))-64);
	eat1
      end
      else if c='"' then begin
	eat1;
	while more and (c<>'"') do begin
	  i:=i+1;
	  text[i]:=c;
	  eat1
	end;
	if not more then warn('%Missing string quote                   ')
	else eat1
      end
      else if c='-' then begin
	eat1;
	blankorcomment;
	getnewline;
	eat1
      end
      else begin
	readatom;
	if atomeq('NULL                                    ') then begin
	  i:=i+1;
	  text[i]:=chr(0)
	end
	else if atomeq('BELL                                    ') then begin
	  i:=i+1;
	  text[i]:=chr(7)
	end
	else if atomeq('BACKSPACE                               ') then begin
	  i:=i+1;
	  text[i]:=chr(8)
	end
	else if atomeq('TAB                                     ') then begin
	  i:=i+1;
	  text[i]:=chr(9)
	end
	else if atomeq('LINEFEED                                ') then begin
	  i:=i+1;
	  text[i]:=chr(10)
	end
	else if atomeq('FORMFEED                                ') then begin
	  i:=i+1;
	  text[i]:=chr(12)
	end
	else if atomeq('RETURN                                  ') then begin
	  i:=i+1;
	  text[i]:=chr(13)
	end
	else if atomeq('ESCAPE                                  ') then begin
	  i:=i+1;
	  text[i]:=chr(27)
	end
	else if atomeq('SPACE                                   ')
	     or atomeq('BLANK                                   ') then begin
	  i:=i+1;
	  text[i]:=chr(32)
	end
	else if atomeq('RUBOUT                                  ')
	     or atomeq('DELETE                                  ') then begin
	  i:=i+1;
	  text[i]:=chr(127)
	end
	else blankorcomment
      end
    until not more;
    size:=i
  end
end;

procedure parsetermname(index: integer);
begin
  if newterm then putterm;
  newterm:=true;
  clearterm;
  parsecursorop(index);
  writeln(tty,'Processing ', feature[index].text:feature[index].size);
end;

procedure parse;
var
  index: integer;
  colonfound: Boolean;
  syntax: fttype;
begin
  colonfound:=uptocolon;
  index:=lookuptag;
  if (not colonfound) and (index>0) then begin
    warn('%Tag must end with colon                ');
    colonfound:=true
  end;
  if (not colonfound) and (taglength>0) then
    warn('%Can''t parse garbage                    ')
  else if index=0 then begin
    if taglength>0 then
      warn('%Tag not found                          ')
  end
  else begin
    eat1;
    syntax:=feature[index].syntax;
    index:=feature[index].synonyme;
    if (index >= 30) and (index <= 41) then newdcaflag := true;
    if (index >= 39) and (index <= 41) then exceptions := true;
    if (index >= 43) and (index <= 50) then newscrflag := true;
    if (not newterm) and (syntax<>termname)
    then error('?Entry must begin with terminal name    ')
    else case syntax of
      termname:	parsetermname(index);
      cursorop:	parsecursorop(index);
      number:	parsenumber(index);
      yesno:	parseyesno(index);
      tristate:	parsetristate(index);
    end;
  end;
  getnewline;
end;

procedure initerm;
var i: integer;
begin
  for i:=1 to nfeatures do begin
    feature[i].syntax:=cursorop;
    feature[i].synonyme:=i;
  end;
  clearterm;
  feature[1].tag:='TERMINAL NAME:                          ';
  feature[1].syntax:=termname;
  feature[2].tag:='CURSOR UP:                              ';
  feature[3].tag:='CURSOR DOWN:                            ';
  feature[4].tag:='CURSOR LEFT:                            ';
  feature[5].tag:='CURSOR RIGHT:                           ';
  feature[6].tag:='CURSOR HOME:                            ';
  feature[7].tag:='ERASE FROM CURSOR TO END OF LINE:       ';
  feature[8].tag:='TIME NEEDED FOR ERASING TO END OF LINE: ';
  feature[8].syntax:=number;
  feature[9].tag:='CLEAR SCREEN:                           ';
  feature[10].tag:='TIME NEEDED TO CLEAR SCREEN:            ';
  feature[10].syntax:=number;
(***** The following two are obsoleted *****)
  feature[11].tag:='    DIRECT CURSOR ADDRESSING CHARACTERS:';
  feature[12].tag:='     DIRECT CURSOR ADDRESSING ALGORITHM:';
  feature[12].syntax:=number;
(***** End of obsoleted features *****)
  feature[13].tag:='INSERT CHARACTER MODE ON:               ';
  feature[14].tag:='INSERT CHARACTER MODE OFF:              ';
  feature[15].tag:='DELETE CHARACTER:                       ';
  feature[16].tag:='TIME NEEDED TO INSERT/DELETE CHARACTER: ';
  feature[16].syntax:=number;
(***** The following two are obsoleted *****)
  feature[17].tag:='                            INSERT LINE:';
  feature[18].tag:='                            DELETE LINE:';
(***** End of obsoleted features *****)
  feature[19].tag:='TIME NEEDED TO INSERT/DELETE LINE:      ';
  feature[19].syntax:=number;
(***** The following is obsoleted *****)
  feature[20].tag:='                REGION SCROLL ALGORITHM:';
  feature[20].syntax:=number;
(***** End of obsoleted feature *****)
  feature[21].tag:='HIGHLIGHT MODE ON:                      ';
  feature[22].tag:='HIGHLIGHT MODE OFF:                     ';
  feature[23].tag:='TERMINAL INITIALIZATION STRING:         ';
  feature[24].tag:='TERMINAL DEACTIVATION STRING:           ';
  feature[25].tag:='TERMINAL WIDTH:                         ';
  feature[25].syntax:=number;
  feature[26].tag:='TERMINAL PAGE LENGTH:                   ';
  feature[26].syntax:=number;
  feature[27].tag:='FIXED TAB STOPS EVERY 8 COLUMNS:        ';
  feature[27].syntax:=yesno;
  feature[28].tag:='WRAP AROUND FROM LAST COLUMN:           ';
  feature[28].syntax:=tristate;
  feature[29].tag:='FILL CHARACTER:                         ';

(* --- New DCA handling --- *)

  feature[30].tag := 'DCA LEAD IN STRING:                     ';
  feature[31].tag := 'DCA INTERMEDIATE STRING:                ';
  feature[32].tag := 'DCA TRAILING STRING:                    ';
  feature[33].tag := 'DCA COORDINATES DECIMAL:                ';
  feature[33].syntax := yesno;
  feature[34].tag := 'DCA COLUMN FIRST:                       ';
  feature[34].syntax := yesno;
  feature[35].tag := 'DCA ROW NEGATE:                         ';
  feature[35].syntax := yesno;
  feature[36].tag := 'DCA COLUMN NEGATE:                      ';
  feature[36].syntax := yesno;
  feature[37].tag := 'DCA ROW OFFSET:                         ';
  feature[37].syntax := number;
  feature[38].tag := 'DCA COLUMN OFFSET:                      ';
  feature[38].syntax := number;
  feature[39].tag := 'DCA EXCEPTION BEGIN:                    ';
  feature[39].syntax := number;
  feature[40].tag := 'DCA EXCEPTION END:                      ';
  feature[40].syntax := number;
  feature[41].tag := 'DCA EXCEPTION OFFSET:                   ';
  feature[41].syntax := number;
  feature[42].tag := 'CR GOES TO LEFT MARGIN:                 ';
  feature[42].syntax := yesno;

(* --- New region scroll handling --- *)

  feature[43].tag := 'VT100 REGION SCROLL:                    ';
  feature[43].syntax := yesno;
  feature[44].tag := 'INSERT LINE:                            ';
  feature[45].tag := 'TERMINATE INSERT LINE:                  ';
  feature[46].tag := 'DELETE LINE:                            ';
  feature[47].tag := 'TERMINATE DELETE LINE:                  ';
  feature[48].tag := 'I/D MULTIPLE LINES:                     ';
  feature[48].syntax := yesno;
  feature[49].tag := 'I/D LINE ARGUMENT DECIMAL:              ';
  feature[49].syntax := yesno;
  feature[50].tag := 'I/D LINE ARGUMENT OFFSET:               ';
  feature[50].syntax := number;
end;

begin
  write(tty, 'Input file /AMIS.DEC/ : ');
  atombuf:='AMIS.DEC                                ';
  atomlength:=rdline(atombuf);
  reset(infile,atombuf);
  write(tty, 'Output file /AMIS.TRM/ : ');
  atombuf:='AMIS.TRM                                ';
  atomlength:=rdline(atombuf);
  rewrite(outfile,atombuf);
  initerm;
  more:=true;
  newterm:=false;
  while more do parse;
  if newterm then putterm
  else error('?Unexpected end of file                 ');
9:
end.
