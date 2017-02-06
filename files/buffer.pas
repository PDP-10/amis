(* AMIS buffer handler. *)	(* -*-PASCAL-*- *)

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

module buffer;

const
  strsize   = 40;		(* universal string length *)
  ctrlatsign = 0;		(* null *)
  ctrlj	    = 10;		(* linefeed *)
  LineFeed  = 10;		(* Fuck U, Red Baron! *)
  ctrlm	    = 13;		(* carriage return *)
  null	    = ctrlatsign;	(* null again *)
(*@VMS:  DskSize   = 512; *)
(*@TOPS: DskSize   = 640; *)

  chunksize = dsksize;		(* which is also maximum size of a chunk *)
  maxkillbuf= 8;		(* number of kill buffers *)
  save_corpse = true;		(* mnemonics for murder procedure *)
  dont_save_corpse = false;
  answer    = 42;		(* the ultimate answer to the universe *)

 
type
  bufpos = integer;
  string = packed array[1..strsize] of char;

  refchunk = ^textchunk;		(* pointer to a text chunk *)

  textchunk = packed array[1..chunksize] of char;

  refcdc = ^cdc;			(* pointer to a CDC *)

  cdc = packed record			(* Chunk Data Control-template *)
	  size: integer;		(* number of chars in chunk *)
	  left,right: refcdc;		(* links to other CDCs *)
	  tchunk: refchunk;		(* pointer to the text *)
	end;

  chunkpos = record
	       chunk: refcdc;		(* which chunk *)
	       pos: integer		(* offset for character position *)
	     end;

  refbuffer = ^bufferheader;

  bufferheader = record
		   size: bufpos;	(* buffer size *)
		   left,right: refbuffer;
		   number: integer;	(* number used to refer to buffer *)
		   head: refcdc;	(* actual header *)
		   dot: bufpos;		(* current position *)
		   modified: boolean	(* true if buffer has been modified *)
		 end;



(* Variable declarations *)

var
  zbuf	    : refbuffer; (* pointer to buffer number 0 *)
  maxbuf    : integer;	 (* highest positive buffer number *)
  minqreg   : integer;	 (* lowest negative (Qreg) buffer number *)
  cbuf	    : integer;	 (* index for current buffer *)
  csize	    : integer;	 (* size of current buffer *)
  chead	    : refcdc;	 (* head of current buffer *)
  cdot	    : bufpos;	 (* the current position in the current buffer *)
  cmodified : Boolean;	 (* true if the current buffer has been modified *)
  coffin    : integer;	 (* index for current kill buffer *)
  cc	    : refcdc;	 (* pointer to CDC for the "current chunk" *)
  icc	    : bufpos;	 (* buffer position of 1st char in current chunk *)
  rvoid	    : refcdc;	 (* used to void refcdc-type values *)
  gcc	    : refcdc;	 (* pointer to current "GC chunk" *)
  gchead    : refcdc;	 (* header for the buffer currently being GC:ed *)
  gcbuf	    : refbuffer; (* pointer to the buffer currently being GC:ed *)
  gcoff	    : boolean;   (* true if GC should not be performed. *)
  eol	    : string;	 (* string containing the end-of-line sequence *)
  eolnp     : array [1..strsize] of char; (* also unpacked, for speed. *)
  eolcount  : integer;	 (* length of end-of-line sequence *)
  eollf     : boolean;	 (* true if single line feed is eol too. *)
  ExactCase : boolean;   (* true if searches dont match upper and lower case *)
  cdccache  : refcdc;	 (* cdc cache. *)

(* External routines needed. Note: procedures wininsert, etc. begin *)
(* with "win" for historical reasons. *)
 
procedure wininsert(i: bufpos); external;	(* from module SCREEN *)
procedure windelete(i: bufpos); external;	(* from module SCREEN *)
procedure winsetdot(i: bufpos); external;	(* from module SCREEN *)
procedure winbuf(n: integer); external;		(* from module SCREEN *)
procedure error(s: string); external;		(* from module MAIN   *)
procedure bug(s: string); external;		(* from module TTYIO  *)
function upcase(c: char): char; external;	(* from module AMILIB *)
function DownCase(c: char): char; external;	(* from module AMILIB *)
function StrLength(s: string): integer; external;
 
(* The following routines make up the machine-dependent buffer handler *)
(* All of them come from sub-module MBUF *)
 
procedure movebytes(sc,dc: refchunk; si,di,count: integer); external;
function findchar(c1,c2: char; r: refchunk; pos,range: integer): integer;
  external;
function bfindchar(c1,c2: char; r: refchunk; pos,range: integer): integer;
  external;

(* Here it comes ... *)

(*--------------------------------------NIBERROR-----------------------------*)

procedure niberror;
begin
  error('NIB? Character Not In Buffer            ')
end;


(*--------------------------------------FINDBACKWARDS------------------------*)

procedure findbackwards(i: bufpos);	(* findbackwards and findforward *)
					(* move global variables cc and icc *)
					(* to the chunk that contains the *)
					(* character preceding i, or if i=0, *)
					(* the dummy header chunk. If you *)
					(* want the character following i *)
					(* instead, do find...(i+1). *)
begin
  if i<0 then bug('Findbackwards: argument out of range    ');
  repeat
    cc:=cc^.left;
    icc:=icc-cc^.size
  until icc<i
end;


(*--------------------------------------FINDFORWARD--------------------------*)

procedure findforward(i: bufpos);
begin
  if i>csize then bug('Findforward: argument out of range      ');
  icc:=icc+cc^.size;
  repeat     
    cc:=cc^.right;
    icc:=icc+cc^.size
  until icc>=i;
  icc:=icc-cc^.size
end;


(*--------------------------------------DELCHUNKS----------------------------*)

procedure delchunks(b,c: refcdc);	(* Delete b-c from the buffer they *)
					(* are in *)
var
  a,z: refcdc;
begin
  a:=b^.left;
  z:=c^.right;
  a^.right:=z;				(* replace right link *)
  z^.left:=a;				(* replace left link *)
end;


(*--------------------------------------FREECHUNKS---------------------------*)

procedure freechunks(c1,c2: refcdc);	(* Release the chunks from c1 to c2 *)
					(* (inclusive), and put them in the *)
					(* free list *)
label 1;
var
  c3,c4: refcdc;
  c3text: refchunk;
begin
  c3:=c1;				(* start with leftmost chunk *)
  while true do begin
    c4:=c3^.right;			(* remember address of next chunk *)
    c3text:=c3^.tchunk;			(* required by compiler bug *)
    if c3text<>nil then			(* free text chunk if we have one *)
      dispose(c3text);
    dispose(c3);			(* free the cdc itself *)
    if c3=c2 then goto 1;		(* quit when c2 is reached *)
    c3:=c4				(* advance to next chunk *)
  end;
1:
end;


(*--------------------------------------GCNEXTBUF----------------------------*)

procedure gcnextbuf;			(* move to GC another buffer *)
begin
  gcbuf:=gcbuf^.right;
  gchead:=gcbuf^.head;
  gcc:=gchead
end;


(*--------------------------------------GC-----------------------------------*)

procedure gc(protected: refcdc);	(* Do a little garbage collecting *)
label 1,2;
var r,oldgcc: refcdc;
begin
  if gcoff then goto 2;		(* The GC may be off. *)
  if gcbuf=zbuf then begin		(* don't touch buffer 0 *)
    gcnextbuf;
    goto 2
  end;
  oldgcc:=gcc;
1:					(* try to find some garbage *)
  r:=gcc^.right;
  if gcc^.size+r^.size>chunksize then begin
    gcc:=r;
    if gcc=gchead then gcnextbuf;
    if (gcc=oldgcc) or (gcbuf=zbuf) then goto 2;
    goto 1
  end;					(* found some. *)
  if gcc<>cc then			(* keep protected pointer and cc *)
  if r<>cc then
  if gcc<>protected then
  if r<>protected then begin
    movebytes(r^.tchunk,gcc^.tchunk,0,gcc^.size,r^.size);
    gcc^.size:=gcc^.size+r^.size;
    delchunks(r,r);
    freechunks(r,r);
    goto 2
  end;
  gcc:=r; if gcc<>oldgcc then goto 1;
2:
  gcoff := false;		(* Turn the GC back on. *)
end;


(*--------------------------------------NEWCDC-------------------------------*)

function newcdc: refcdc;
var
  c: refcdc;
  i: integer;
begin
  if cdccache = nil
  then for i := 1 to 30 do begin
    new(c);
    c^.right := cdccache;
    cdccache := c;
  end;
  newcdc := cdccache;
  cdccache := cdccache^.right;
end;

(*--------------------------------------CONSACHUNK---------------------------*)

function consachunk(protected: refcdc): refcdc;  (* Cons a chunk *)
var
  c: refcdc;
begin
  gc(protected);			(* release some garbage *)
  c := newcdc;				(* allocate a new cdc *)
  new(c^.tchunk);			(* allocate a new text chunk *)
  consachunk:=c				(* return constructed chunk *)
end;


(*--------------------------------------CONSABUFFER--------------------------*)

function consabuffer(protected: refcdc): refbuffer;  (* Cons a buffer *)
var
  b: refbuffer;
begin
  gc(protected);			(* release some garbage *)
  new(b);				(* allocate a new buffer *)
  with b^ do begin
    size:=0;
    new(head);				(* allocate a new head cdc *)
    with head^ do begin
      size:=chunksize;			(* this makes other things easy *)
      left:=head;
      right:=head;
      tchunk:=nil;
    end
  end;
  consabuffer:=b			(* return constructed buffer *)
end;


(*--------------------------------------INSCHUNKS----------------------------*)

procedure inschunks(a,b,c: refcdc);	(* Insert b-c after a *)
var
  z: refcdc;
begin
  z:=a^.right;
  a^.right:=b;				(* change right link in a *)
  b^.left:=a;				(* change left link in b *)
  z^.left:=c;				(* change left link in z *)
  c^.right:=z				(* change right link in c *)
end;


(*--------------------------------------INSBUFFERS---------------------------*)

procedure insbuffers(a,b,c: refbuffer);	(* Insert b-c after a *)
var
  z: refbuffer;
begin
  z:=a^.right;
  a^.right:=b;				(* change right link in a *)
  b^.left:=a;				(* change left link in b *)
  z^.left:=c;				(* change left link in z *)
  c^.right:=z				(* change right link in c *)
end;


(*--------------------------------------FINDBUFFER---------------------------*)

function findbuffer(n: integer): refbuffer; (* Finds buffer in linked list *)
var
  b,c: refbuffer;
begin
  b:=nil;
  c:=zbuf^.right;			(* scan forward from buffer 0 *)
  while (b=nil) and (c<>zbuf) do	(* until we find buffer or buffer 0 *)
    if c^.number=n then
      b:=c
    else
      c:=c^.right;
  if b=nil then				(* we didn't find the buffer, so ... *)
    if n<0 then begin			(* ... create it, if it is internal *)
      b:=consabuffer(nil);
      b^.number:=n;
      insbuffers(zbuf^.left,b,b)
    end
    else				(* ... bug, if request from MAIN *)
      bug('Findbuffer: Buffer not found!           ');
  findbuffer:=b
end;


(*--------------------------------------COPY---------------------------------*)

procedure copy(source,dest: chunkpos; count: integer);
					(* Copy count characters from source *)
					(* to dest *)
begin
  movebytes(source.chunk^.tchunk,dest.chunk^.tchunk,source.pos,dest.pos,count)
end;


(*--------------------------------------GETPOS-------------------------------*)

procedure getpos(var x: chunkpos; i: bufpos);
					(* x := chunkpos corresponding to i *)
var j: integer;
begin
  j:=i-icc;
  if j<1 then begin			(* before current chunk? *)
    findbackwards(i);
    j:=i-icc;
  end
  else
    if j>cc^.size then begin		(* after current chunk? *)
      findforward(i);
      j:=i-icc
    end;
  x.chunk:=cc;
  x.pos:=j
end;

(*--------------------------------------MAKEHOLE-----------------------------*)

function makehole(p: chunkpos): refcdc;	(* Make a hole here. Return the *)
					(* right link of p.chunk *)
var
  n: integer;
  q: chunkpos;
  pp: refcdc;
begin
  pp:=p.chunk;
  n:=pp^.size-p.pos;  
  if n=0 then begin			(* maybe we don't need any hole? *)
    makehole:=pp^.right;
  end
  else begin
    with q do begin
      chunk:=consachunk(pp);		(* construct a chunk *)
      pos:=0;
      copy(p,q,n);			(* put text in it *)
      chunk^.size:=n;			(* set the size *)
      pp^.size:=p.pos;			(* delete the copied text *)
      inschunks(pp,chunk,chunk);	(* now insert the new chunk *)
      makehole:=chunk
    end
  end
end;


(*--------------------------------------FINDREGION---------------------------*)

procedure findregion(var a,b: bufpos; i: bufpos);
					(* a:= min(cdot,cdot+i); *)
begin					(* b:= max(cdot,cdot+i)  *)
  if i<0 then begin
    a:=cdot+i; b:=cdot
  end
  else begin
    a:=cdot; b:=cdot+i
  end;
  if a<0 then niberror
  else
    if b>csize then niberror
end;


(*--------------------------------------MURDER-------------------------------*)

procedure murder(i: bufpos; save_corpsep: Boolean);
					(* Delete all characters between *)
					(* dot and dot+i (i may be < 0). *)
					(* If save_corpsep is true, the *)
					(* deleted string will be inserted *)
					(* at the end of the current kill *)
					(* buffer. *)
var
  a,b,n,oldicc: bufpos;
  aa,bb: chunkpos;
  x,y: refcdc;
  k: refbuffer;
begin
  if i<>0 then begin
    findregion(a,b,i);
    n:=b-a;
    if a<0 then niberror		(* (take away these tests later?) *)
    else
      if b>csize then niberror
      else begin
        cdot:=a;
        winsetdot(cdot);		(* prepare SCREEN for the slaughter *)
	getpos(bb,b);
	y:=bb.chunk;
	if (bb.pos>=n) and (y^.size>n) and not save_corpsep
	then begin
	  aa.chunk:=y;			(* delete part of chunk *)
	  aa.pos:=bb.pos-n;
	  copy(bb,aa,y^.size-bb.pos);	(* move down rest of chunk *)
	  y^.size:=y^.size-n
	end
	else begin
	  getpos(aa,a);
	  x:=makehole(aa);		(* x := right part of hole at a *)
	  oldicc:=icc;
	  getpos(bb,b);
	  cc:=aa.chunk; icc:=oldicc;	(* trick to protect cc *)
	  y:=makehole(bb);		(* y := right part of hole at b *)
	  if gchead=chead then gcc:=y;
	  y:=y^.left;
	  delchunks(x,y);		(* delete chunks from buffer *)
	  if save_corpsep then begin
	    k:=findbuffer(-coffin-41);	(* find kill buffer *)
	    with k^ do begin
	      if i>0 then		(* append corpse to kill buffer *)
		inschunks(head^.left,x,y)
	      else
		inschunks(head,x,y);	(* prepend instead *)
	      size:=size+n		(* increment kill buffer size *)
	    end
	  end
	  else freechunks(x,y)		(* release the corpse *)
	end;
        csize:=csize-n;			(* decrement buffer size *)
        cmodified:=true;
        windelete(n)			(* now let SCREEN do its share *)
      end
    end
end;


(*--------------------------------------RCLBUF-------------------------------*)

procedure rclbuf(n: integer);		(* "Recall" buffer n *)
					(* Make it the current one *)
var
  b: refbuffer;
begin
  b:=findbuffer(n);
  with b^ do begin
    csize:=size;
    cdot:=dot;
    cmodified:=modified;
    chead:=head
  end;
  cbuf:=n;
  cc:=chead;
  icc:=-chunksize
end;


(*--------------------------------------STOBUF-------------------------------*)

procedure stobuf(n: integer);		(* Store current buffer in buffer n *)
var
  b: refbuffer;
begin
  b:=findbuffer(n);
  with b^ do begin
    size:=csize;
    head:=chead;
    dot:=cdot;
    modified:=cmodified
  end
end;


(*--------------------------------------COPYBUFFER---------------------------*)

procedure copybuffer(buf: refbuffer);
					(* Insert a copy of buf at dot *)
var
  p: chunkpos;
  s: bufpos;
  x,newchk,pp: refcdc;
begin
  if buf^.size>0 then begin
    getpos(p,cdot);
    rvoid:=makehole(p);
    pp:=p.chunk;
    x:=buf^.head;
    s:=0;
    repeat
      x:=x^.left;			(* go from right to left *)
      newchk:=consachunk(x);
      movebytes(x^.tchunk,newchk^.tchunk,0,0,x^.size);
      inschunks(pp,newchk,newchk);
      newchk^.size:=x^.size;
      s:=s+newchk^.size;
    until x=buf^.head^.right;		(* reached last chunk? *)
    csize:=csize+s;
    cmodified:=true;
    wininsert(s);
    cdot:=cdot+s
  end
end;


(*--------------------------------------CLEARBUFFER--------------------------*)

procedure clearbuffer(buf: refbuffer);	(* Empties buf *)
var first,last: refcdc;
begin
  with buf^ do begin
    if size>0 then begin
      if gchead=head then gcnextbuf;
      first:=head^.right;
      last:=head^.left;
      delchunks(first,last);
      size:=0;
      freechunks(first,last)
    end
  end
end;


(*--------------------------------------OKGETCHAR----------------------------*)

function okgetchar(var c: char; i: bufpos): Boolean;	
					(* Put the i+1th character of the *)
label 1,2;				(* current buffer in c, and return *)
var j: integer;				(* if it is in range *)
begin
  j:=i-icc;
  if i<0 then goto 1;			(* i outside buffer *)
  if j<0 then begin			(* before current chunk? *)
    findbackwards(i+1);
    c:=cc^.tchunk^[i-icc+1]
  end
  else
    if j>=cc^.size then begin		(* after current chunk? *)
      if i>=csize then goto 1;		(* i outside buffer *)
      findforward(i+1);
      c:=cc^.tchunk^[i-icc+1]
    end
    else c:=cc^.tchunk^[j+1];	(* in current chunk! *)
  okgetchar:=true;
  goto 2;
1:okgetchar:=false;
2:
end;





(* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)
(*									     *)
(*		The following are the entry-point routines		     *)
(*									     *)
(* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *)

(*--------------------------------------BufFlags-----------------------------*)

(*@VMS: [global] *)
procedure BufFlags(flags: string);
var c: char;
begin
  c := flags[3];                (* "Display LineFeed as EOL" *)
  if c = '-' then eollf := false;
  if c = '+' then eollf := true;
  c := flags[8];                (* "Case sensitive search" *)
  if c = '-' then ExactCase := false;
  if c = '+' then ExactCase := true;
end;

(*--------------------------------------BUFINIT------------------------------*)

(*@VMS: [global] *)
procedure bufinit;			(* Initialize everything *)
begin
  eol[1]:=chr(ctrlm);			(* init eol string *)
  eol[2]:=chr(ctrlj);
  eolnp[1]:=chr(ctrlm);
  eolnp[2]:=chr(ctrlj);
  eolcount:=2;
  eollf:=false;
  ExactCase:=false;
  coffin:=0;				(* init kill ring pointer *)
  cbuf:=0;				(* no buffer in use yet *)
  maxbuf:=0;				(* highest buffer in use *)
  minqreg:=-48;				(* lowest allocated Qreg number *)
  new(zbuf);				(* create and initialize buffer 0 *)
  with zbuf^ do begin
    size:=-1;
    left:=zbuf;
    right:=zbuf;
    number:=0;
    head:=nil;
    dot:=-1
  end;
  cdccache := nil;		(* cdc cache is empty now. *)
  gcbuf:=zbuf;			(* The four statements moved into this *)
  gchead:=gcbuf^.head;		(* position is the former routine *)
  gcc:=gchead;			(* "GCINIT". *)
  gcoff := false;		(* The GC is normally on. *)
end;


(*--------------------------------------ISETBUF------------------------------*)

(*@VMS: [global] *)
procedure isetbuf(n: integer);		(* invisibly choose buffer n *)
begin
  if cbuf<>0 then
    stobuf(cbuf);
  rclbuf(n)
end;


(*--------------------------------------SETBUF-------------------------------*)

(*@VMS: [global] *)
procedure setbuf(n: integer);		(* choose buffer n *)
begin
  isetbuf(n);
  winbuf(cbuf)
end;


(*--------------------------------------GETBUF-------------------------------*)

(*@VMS: [global] *)
function getbuf: integer;		(* return number of current buffer *)
begin
  getbuf:=cbuf
end;


(*--------------------------------------KILLBUF------------------------------*)

(*@VMS: [global] *)
procedure killbuf(n: integer);		(* kills buffer n *)
var
  b: refbuffer;
  c: refcdc;
begin
  if n<1 then
    bug('Killbuf: Invalid buffer number          ');
  if cbuf<>0 then
    stobuf(cbuf);
  b:=findbuffer(n);
  clearbuffer(b);
  b^.right^.left:=b^.left;		(* remove buffer from linked list *)
  b^.left^.right:=b^.right;
  c:=b^.head;				(* required by compiler bug *)
  dispose(c);				(* free head cdc block *)
  dispose(b);				(* free buffer block itself *)
  if cbuf<>0 then
    rclbuf(cbuf)
end;

(*--------------------------------------CREATEBUF----------------------------*)

(*@VMS: [global] *)
function createbuf: integer;		(* Create a new buffer and return *)
					(* number *)
var
  b: refbuffer;
begin
  b:=consabuffer(nil);			(* create a buffer *)
  maxbuf:=maxbuf+1;			(* increment max buffer number *)
  with b^ do begin
    number:=maxbuf;			(* save buffer number *)
    dot:=0;
    modified:=false
  end;
  insbuffers(zbuf,b,b);			(* insert buffer into linked list *)
  createbuf:=maxbuf			(* return buffer number *)
end;


(*--------------------------------------INSERT-------------------------------*)

(*@VMS: [global] *)
procedure insert(c: char);		(* Insert c at dot *)
var
  p,q: chunkpos;
  x: refcdc;
begin
  getpos(p,cdot);
  with p do begin
    if chunk^.size=chunksize then begin
      rvoid:=makehole(p);		(* chunk full? - then split it *)
      if chunk^.size=chunksize then
      begin				(* hack that forces consing when *)
	x:=consachunk(nil);		(* makehole refuses to do so *)
	x^.size:=0;
	inschunks(chunk,x,x);
	chunk:=x;
	pos:=0
      end
    end
    else if pos<chunk^.size then begin
      q.chunk:=chunk; q.pos:=pos+1;	(* make room for an extra char *)
      copy(p,q,chunk^.size-pos)
    end;
    chunk^.tchunk^[pos+1] := c;		(* store character in hole *)
    chunk^.size:=chunk^.size+1		(* increment chunk size *)
  end;
  csize:=csize+1;			(* increment buffer size *)
  cmodified:=true;			(* buffer has been modified *)
  wininsert(1);				(* tell SCREEN to insert the char *)
  cdot:=cdot+1
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure NInsert(c: char; n: integer);
var
  i: integer;
begin
  for i := 1 to n do Insert(c);
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure InsString(Str: string);
var
  Pos: integer;
begin
  for Pos := 1 to StrLength(Str) do insert(Str[Pos])
end;

(*--------------------------------------RPLACHAR-----------------------------*)

(*@VMS: [global] *)
procedure rplachar(c: char);		(* Replace the character after dot *)
var p: chunkpos;
begin
  if cdot=csize then
    bug('Rplachar: Dot at end of buffer          ');
  getpos(p,cdot+1);
  with p do chunk^.tchunk^[pos] := c;
  cmodified:=true;
  windelete(1);
  wininsert(1); cdot:=cdot+1
end;


(*--------------------------------------DELETE-------------------------------*)

(*@VMS: [global] *)
procedure delete(i: bufpos);		(* Delete i characters after dot *)
begin
  murder(i,dont_save_corpse)
end;


(*--------------------------------------KILL---------------------------------*)

(*@VMS: [global] *)
procedure kill(i: bufpos);		(* Delete i characters after dot and *)
					(* append to the current kill buffer *)
begin
  murder(i,save_corpse)
end;


(*--------------------------------------KILLPUSH-----------------------------*)

(*@VMS: [global] *)
procedure killpush;			(* select a new, empty kill buffer *)
var
  k: refbuffer;
begin
  coffin:=(coffin+1) mod maxkillbuf;
  k:=findbuffer(-coffin-41);
  clearbuffer(k)
end;


(*--------------------------------------UNKILL-------------------------------*)

(*@VMS: [global] *)
procedure unkill(n: integer);		(* Insert a copy of the n:th kill *)
					(* buffer (the most recent is 1)  *)
var index : integer;			(* after dot. *)
begin
  index:=(coffin-n+1) mod maxkillbuf;	(* I have to use a temporary  *)
  if index<0 then			(* Index gets negative if n>coffin *)
    index:=index+maxkillbuf;		(* on some computers. *)
  copybuffer(findbuffer(-index-41))	(* variable here, because our Humbug *)
end;					(* Pascal compiler refuses to  *)
					(* generate the right code otherwise *)


(*--------------------------------------UNK2STRING---------------------------*)

(*@VMS: [global] *)
procedure Unk2String(var Line: string; var Pos: integer);
var
  currentBuffer: integer;
  c: char;
  i: integer;
begin
  CurrentBuffer := cbuf;
  isetbuf(-41-coffin);
  i := 0;
  while (Pos < StrSize) and okgetchar(c,i)
  do begin
    Line[Pos] := c;
    Pos := Pos + 1;
    i := i + 1;
  end;
  isetbuf(CurrentBuffer);
end;

(*--------------------------------------KILLPOP------------------------------*)

(*@VMS: [global] *)
procedure killpop;			(* Pops the kill ring one step *)
begin
  coffin:=(coffin+maxkillbuf-1) mod maxkillbuf
end;

(*--------------------------------------QX-----------------------------------*)

(*@VMS: [global] *)
procedure qx(qreg: integer; i: bufpos);	(* Put text in Q-register *)
var
  a,b: bufpos;
  n: integer;
  q: refbuffer;
  pp: chunkpos;
  x: refcdc;
begin
  q:=findbuffer(qreg);
  clearbuffer(q);
  if i<>0 then begin
    findregion(a,b,i);
    repeat
      getpos(pp,a+1); pp.pos:=pp.pos-1;
      x:=consachunk(nil);
      with pp do begin
        n:=chunk^.size-pos;
	if n>b-a then n:=b-a;		(* n:= min(n,b-a) *)
	movebytes(chunk^.tchunk,x^.tchunk,pos,0,n);
      end;
      x^.size:=n;
      with q^ do begin
        inschunks(head^.left,x,x);	(* put text in Q-reg. buffer *)
	size:=size+n
      end;
      a:=a+n
    until a=b
  end
end;


(*--------------------------------------QG-----------------------------------*)

(*@VMS: [global] *)
procedure qg(qreg: integer);		(* Get Q-register *)
var
  b: refbuffer;
begin
  b:=findbuffer(qreg);
  copybuffer(b)
end;


(*--------------------------------------GETDOT-------------------------------*)

(*@VMS: [global] *)
function getdot: bufpos;		(* Return the value of dot *)
begin
  getdot:=cdot
end;


(*--------------------------------------SETDOT-------------------------------*)

(*@VMS: [global] *)
procedure setdot(i: bufpos);		(* Set dot to i *)
begin
  if (i<0) or (i>csize) then niberror	(* check range of argument *)
  else begin
    cdot:=i;
    winsetdot(cdot)			(* tell SCREEN about it *)
  end
end;


(*--------------------------------------GETSIZE------------------------------*)

(*@VMS: [global] *)
function getsize: bufpos;		(* Returns size of buffer *)
begin
  getsize:=csize
end;


(*--------------------------------------GETCHAR------------------------------*)

(*@VMS: [global] *)
function getchar(i: bufpos): char;	(* Return the i+1th character of the *)
					(* current buffer *)
var c: char;
begin
  if okgetchar(c,i) then getchar:=c
  else niberror
end;


(*--------------------------------------GETNULL------------------------------*)

(*@VMS: [global] *)
function getnull(i: bufpos): char;	(* Like getchar, but returns null if *)
					(* argument is out of range *)
var c: char;
begin
  if okgetchar(c,i) then getnull:=c
  else getnull:=chr(null)
end;


(*--------------------------------------BGETCHAR-----------------------------*)

(*@VMS: [global] *)
function bgetchar(i: bufpos): char;	(* Like getchar, but bug if argument *)
					(* out of range *)
var c: char;
begin
  if okgetchar(c,i) then bgetchar:=c
  else
    bug('Bgetchar: argument out of range         ')
end;


(*--------------------------------------INSBLOCK-----------------------------*)

(*@VMS: [global] *)
procedure insblock(s: refchunk; c: integer);
					(* Insert c characters from the disk *)
					(* block s at dot *)
var p: chunkpos; x: refcdc;
begin
  getpos(p,cdot);
  rvoid:=makehole(p);
  gcoff := true;		(* Inhibit GC on this call to consachunk. *)
  x:=consachunk(nil);			(* cons a new chunk to put chars in *)
  x^.size:=c;
  inschunks(p.chunk,x,x);
  movebytes(s,x^.tchunk,0,0,c);		(* transfer the characters *)
  csize:=csize+c;
  cmodified:=true;
  wininsert(c);
  cdot:=cdot+c
end;


(*--------------------------------------GETBLOCK-----------------------------*)

(*@VMS: [global] *)
procedure getblock(p: bufpos; d: refchunk);
					(* Fill the disk block d with chars *)
					(* from buffer position p *)
label 1;
var
  i: bufpos; pp: chunkpos;
  s,n: integer;
begin
  i:=p;					(* start at p *)
  s:=dsksize;				(* s = no. of chars to write *)
  repeat
    if i=csize then goto 1;		(* quit at end of buffer *)
    getpos(pp,i+1);
    with pp do begin
      pos:=pos-1;
      n:=chunk^.size-pos;		(* remaining chars in this chunk *)
      if n>s then n:=s;			(* n:= min(n,s) *)
      movebytes(chunk^.tchunk,d,pos,dsksize-s,n);
      s:=s-n;
      i:=i+n
    end
  until s=0;
1:
end;


(*--------------------------------------BUFSEARCH----------------------------*)

(*@VMS: [global] *)
function bufsearch(s: string; len, arg: integer; n: bufpos): Boolean;
					(* Search for the argth occurence of *)
					(* string s of length len, between *)
					(* dot and dot+n (n=0 => to end of *)
					(* buffer). Search backwards if arg *)
					(* is negative. If succesful, place *)
					(* dot immediately AFTER the match, *)
					(* and return true. Otherwise return *)
					(* false and don't move dot. *)
label 1,2,3,4,5;

var
  ch	       : char;
  upper,lower  : array[1..strsize] of char;
  stop	       : bufpos;
  sdot,oldsdot : bufpos;
  i,k,count    : integer;
  spos,pos,inc : integer;
  dummy	       : chunkpos;

begin
  if len>strsize then bug('Bufsearch: String length too large      ');
  if len<=0 then goto 4;
  if arg=0 then bug('Bufsearch: Aaaarrrrrrrrrgggghhh = 0     ');
  for i:=1 to len do begin
    ch := s[i];
    if ExactCase then begin
      upper[i] := ch;
      lower[i] := ch;
    end else begin
      upper[i] := UpCase(ch);
      lower[i] := DownCase(ch)
    end;
  end;
  count:=arg;
  sdot:=cdot;
  oldsdot:=-1;
  if arg>0 then

  begin					(* ----- Search Forward ----- *)
    spos:=0;
    stop:=csize;
    if n>0 then
      if cdot+n<csize then
        stop:=cdot+n;
    repeat
      if sdot=stop then goto 4;
      getpos(dummy,sdot+1);
      repeat
        spos:=spos+1;
        while true do begin		(* look for s[spos] *)
	  pos:=sdot-icc;
	  k:=cc^.size-pos;
	  if k>stop-sdot then k:=stop-sdot;
	  inc:=findchar(upper[spos],lower[spos],cc^.tchunk,pos,k);
	  if inc>0 then goto 1;
	  with cc^ do begin		(* go to next chunk *)
	    icc:=icc+size;
	    sdot:=icc;
	    if sdot>=stop then begin
	      icc:=icc-size;
	      goto 4			(* lose *)
	    end;
	    cc:=right;
	  end
	end;
      1:
        sdot:=sdot+inc
      until spos=len;			(* have we found all characters? *)
      if sdot=oldsdot then begin
        count:=count-1;			(* count down arg *)
	if count=0 then goto 3;		(* Win! *)
	sdot:=sdot-len+1		(* go for next match *)
      end
      else begin			(* possible win... *)
        oldsdot:=sdot;
	sdot:=sdot-len
      end;
      spos:=0
    until false
  end

  else

  begin					(* ----- Search Backwards ----- *)
    spos:=len;
    repeat
      if sdot=0 then goto 4;
      getpos(dummy,sdot);
      repeat
        while true do begin		(* look for s[spos] *)
	  pos:=sdot-icc;
	  inc:=bfindchar(upper[spos],lower[spos],cc^.tchunk,pos,pos);
	  if inc>0 then goto 2;
	  sdot:=icc;
	  if sdot=0 then goto 4;	(* lose *)
	  cc:=cc^.left;
	  icc:=icc-cc^.size;
	end;
      2:
        sdot:=sdot-inc;
	spos:=spos-1;
      until spos=0;			(* found all chars? *)
      if sdot=oldsdot then begin
        count:=count+1;			(* count up (!) arg *)
	sdot:=sdot+len;
	if count=0 then goto 3;		(* Win! *)
	sdot:=sdot-1  (* ??? *)
      end
      else begin
        oldsdot:=sdot;
	sdot:=sdot+len
      end;
      spos:=len
    until false
  end;

3:cdot:=sdot;				(* winning exit *)
  winsetdot(cdot);
  bufsearch:=true;
  goto 5;
4:bufsearch:=false;			(* losing exit *)
5:
end;


(*--------------------------------------EOLSIZE------------------------------*)

(*@VMS: [global] *)
function eolsize: integer;
begin
  eolsize:=eolcount
end;


(*--------------------------------------ATEOL--------------------------------*)
(*  True if end-of-line follows (d>0) or precedes (d<0) i                    *)

(*@VMS: [global] *)
function ateol(i: bufpos; d: integer): Boolean;
label 1;
var j: integer;
begin
  ateol:=false;
  if d>0 then begin
    if eollf then begin
      if i >= csize then goto 1;
      if bgetchar(i) = chr(LineFeed) then begin
	ateol := true; goto 1;
      end;
    end;
    if i>csize-eolcount then goto 1;	(* Too near end of buffer *)
    for j:=1 to eolcount do
    if bgetchar(i+j-1)<>eolnp[j] then goto 1;
    ateol:=true
  end else if d<0 then begin
    if eollf then begin
      if i < 1 then goto 1;
      if bgetchar(i-1) = chr(LineFeed) then begin
	ateol := true; goto 1;
      end;
    end;
    if i<eolcount then goto 1;		(* Too near start of buffer *)
    for j:=1 to eolcount do
    if bgetchar(i+j-1-eolcount)<>eolnp[j] then goto 1;
    ateol:=true
  end;
1:
end;


(*--------------------------------------INSEOL-------------------------------*)

(*@VMS: [global] *)
procedure inseol;			(* insert an end-of-line string *)
var i: integer;
begin
  for i:=1 to eolcount do insert(eolnp[i])
end;


(*--------------------------------------EOLSTRING----------------------------*)

(*@VMS: [global] *)
procedure eolstring(var s: string; var l: integer);
					(* Return end of line string and its *)
					(* length *)
begin
  s:=eol;
  l:=eolcount
end;

(*--------------------------------------GETLINE------------------------------*)

(*@VMS: [global] *)
function getline(i: integer): bufpos;	(* Return the position of the *)
					(* beginning of the ith line *)
					(* following the line dot is in. *)
					(* Negative i means lines above this *)
					(* one, i=0 means this line *)
var oldcdot: bufpos;
begin
  oldcdot:=cdot;
  if i>0 then begin
    if cdot>0 then cdot:=cdot-1;
    if not bufsearch(eol,eolcount,i,0) then
      cdot:=csize
  end
  else begin
    if not bufsearch(eol,eolcount,i-1,0) then
      cdot:=0
  end;
  getline:=cdot;
  cdot:=oldcdot;
  winsetdot(cdot)
end;


(*--------------------------------------ENDLINE------------------------------*)

(*@VMS: [global] *)
function endline: bufpos;		(* Return the position of the end *)
					(* of the current line *)
var oldcdot: bufpos;
begin
  oldcdot:=cdot;
  if cdot>0 then cdot:=cdot-1;
  if bufsearch(eol,eolcount,1,0) then begin
    endline:=cdot-eolcount;
    winsetdot(oldcdot)
  end
  else
    endline:=csize;
  cdot:=oldcdot
end;


(*--------------------------------------GETMODIFIED--------------------------*)

(*@VMS: [global] *)
function getmodified: Boolean;		(* Find out if the buffer *)
					(* has been modified *)
begin
  getmodified:=cmodified
end;


(*--------------------------------------SETMODIFIED--------------------------*)

(*@VMS: [global] *)
procedure setmodified(v: Boolean);	(* Set or clear modflag *)
begin
  cmodified:=v
end;


(*--------------------------------------SWAPREGIONS--------------------------*)

(*@VMS: [global] *)
procedure swapregions(i1,i2,i3,i4: bufpos);	(* Swap regions. *)

var
  nogood: Boolean;
  oldcoffin: integer;
  oldcdot: bufpos;
  b4711: refbuffer;
  n1,n2: bufpos;
  jb1,je1,jb2,je2: bufpos;
  b1,e1,b2,e2: chunkpos;
  start1,start2: refcdc;

procedure sort(var x,y: bufpos);	(* sort x & y ascending *)
var tmp: bufpos;
begin
  if x>y then begin
    tmp:=x; x:=y; y:=tmp;		(* exchange x & y *)
    nogood:=true
  end
end;

begin
  jb1:=i1; je1:=i2; jb2:=i3; je2:=i4;
  nogood:=true;				(* sort jb1,je1,jb2,je2 ascending *)
  while nogood do begin		
    nogood:=false;
    sort(jb1,je1);
    sort(je1,jb2);
    sort(jb2,je2)
  end;
  if (jb1<0) or (je2>csize) then
    bug('Swapregions: argument out of range      ');
  n1:=je1-jb1;				(* length of 1st region *)
  n2:=je2-jb2;				(* length of 2nd region *)
  oldcdot:=cdot;
  setdot(jb1);

  (* WARNING! Ugly hack follows. Sensitive persons close their eyes! *)

  oldcoffin:=coffin;
  coffin:=4711;				(* a non-existent kill buffer! *)
  kill(n1);				(* kill 1st region *)
  setdot(jb2-n1);		
  b4711:=findbuffer(-4752);		(* GAAAAAKKKKK!!!!!! *)
  copybuffer(b4711);			(* unkill it *)
  clearbuffer(b4711);		
  setdot(jb2);
  kill(n2);				(* kill 2nd region *)
  setdot(jb1);			
  copybuffer(b4711);			(* unkill it *)
  clearbuffer(b4711);
  coffin:=oldcoffin;
  setdot(oldcdot)
end;


(*--------------------------------------QCOPY--------------------------------*)

(*@VMS: [global] *)
procedure qcopy(qfrom, qto: integer);	(* Copy a Q register *)
var
  source, dest: refbuffer;
  x, newchk: refcdc;
begin
  stobuf(cbuf);			(* uncache variables... *)
  source:=findbuffer(qfrom);
  dest:=findbuffer(qto);
  clearbuffer(dest);
  (* The following code is almost the same as in Copybuffer. *)
  (* Someday there will be a common copying procedure... *)
  if source^.size>0 then begin
    x:=source^.head;
    with dest^ do begin
      repeat
	x:=x^.left;			(* go from left to right *)
	newchk:=consachunk(x);
	movebytes(x^.tchunk,newchk^.tchunk,0,0,x^.size);
	inschunks(head,newchk,newchk);
	newchk^.size:=x^.size;
	size:=size+newchk^.size
      until x=source^.head^.right	(* reached last chunk? *)
    end
  end
end;

  
(*--------------------------------------QCREATE------------------------------*)

(*@VMS: [global] *)
function qcreate: integer;		(* Create a new Qreg and return *)
					(* number *)
var
  b: refbuffer;
begin
  b:=consabuffer(nil);			(* create a buffer *)
  minqreg:=minqreg-1;			(* decrement min Qreg number *)
  with b^ do begin
    number:=minqreg;			(* save buffer number *)
    dot:=0;
    modified:=false
  end;
  insbuffers(zbuf,b,b);			(* insert buffer into linked list *)
  qcreate:=minqreg			(* return buffer number *)
end;


(*--------------------------------------QGETSIZE-----------------------------*)

(*@VMS: [global] *)
function qgetsize(qreg: integer): integer; (* Obtain size of Qreg *)
var cretin: refbuffer;
begin
  cretin:=findbuffer(qreg);
  qgetsize:=cretin^.size
end;


(*--------------------------------------QGETDOT------------------------------*)

(*@VMS: [global] *)
function qgetdot(qreg: integer): integer; (* Obtain dot of Qreg *)
var cretin: refbuffer;
begin
  cretin:=findbuffer(qreg);
  qgetdot:=cretin^.dot
end;


(*--------------------------------------QSETDOT------------------------------*)

(*@VMS: [global] *)
procedure qsetdot(qreg: integer; i: bufpos); (* Set Qreg dot *)
var cretin: refbuffer;
begin
  cretin:=findbuffer(qreg);
  with cretin^ do
    if (i<0) or (i>size) then
      bug('QSetDot: dot out of range.              ')
    else dot:=i
end;


(*--------------------------------------QINSERT------------------------------*)

(*@VMS: [global] *)
procedure qinsert(qreg: integer; c: char);
var thisbuf: integer;
begin
  thisbuf:=cbuf;
  isetbuf(qreg);
  insert(c);
  isetbuf(thisbuf)
end;


(*--------------------------------------QDELETE------------------------------*)

(*@VMS: [global] *)
procedure qdelete(qreg: integer; i: bufpos);
var thisbuf: integer;
begin
  thisbuf:=cbuf;
  setbuf(qreg);
  delete(i);
  setbuf(thisbuf)
end;


(*--------------------------------------QGETCHAR-----------------------------*)

(*@VMS: [global] *)
function qgetchar(qreg: integer; i: bufpos): char;
var thisbuf: integer; c: char;
begin
  thisbuf:=cbuf;
  isetbuf(qreg);
  if okgetchar(c,i) then qgetchar:=c
  else bug('QGetChar: argument out of range         ');
  isetbuf(thisbuf)
end;


(*--------------------------------------MAIN---------------------------------*)

(*@TOPS: begin end. *)
(*@VMS: end. *)
