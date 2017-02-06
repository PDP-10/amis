(* -*-PASCAL-*- *)

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

(****************************************************************************)
(*                                                                          *)
(* This module contains definitions in Pascal of BUFFER routines that	    *)
(* should be coded in assembly language for high speed and better	    *)
(* memory control. These Pascal routines are intended as an		    *)
(* implementation guide, and as a way of making things run initially.	    *)
(*                                                                          *)
(****************************************************************************)

module mbuf;

const
  strsize = 40;			(* universal string length *)

(*@VMS:  chunksize = 512; *)
(*@TOPS: chunksize = 640; *)

type
  bufpos = integer;
  string = packed array[1..strsize] of char;
  textchunk = packed array[1..chunksize] of char;

  refchunk = ^textchunk;		(* pointer to a text chunk *)

(*--------------------------------------MOVEBYTES----------------------------*)

(*@VMS: [global] *)
procedure movebytes(sc,dc: refchunk; si,di,count: integer);
					(* Move count characters from chunk *)
var k: integer;				(* sc to chunk dc, starting at  *)
begin					(* offsets si and di. Offsets are *)
  if (sc=dc) and (si<di) then		(* zero-based. *)
    for k:=0 to count-1 do	
      dc^[di+count-k]:=sc^[si+count-k]
  else				
    for k:=1 to count do	
      dc^[di+k]:=sc^[si+k]	
end;				

(*--------------------------------------FINDCHAR-----------------------------*)

(*@VMS: [global] *)
function findchar(ch1,ch2: char; r: refchunk; pos,range: integer): integer;
					(* Search for a character that  *)
label 1;				(* matches ch1 or ch2. Start at *)
var ch: char; i: integer;		(* offset (zero-based) pos in chunk *)
begin					(* r, and stop when range chars have *)
  for i:=pos to pos+range-1 do begin	(* been tested, or a match is found. *)
    ch:=getbyte(r,i);			(* On success, return the number of *)
    if ch=ch1 then goto 1;		(* tested characters, otherwise 0. *)
    if ch=ch2 then goto 1
  end;
  i:=pos-1;
1:findchar:=i-pos+1
end;


(*--------------------------------------BFINDCHAR----------------------------*)

(*@VMS: [global] *)
function bfindchar(ch1,ch2: char; r: refchunk; pos,range: integer): integer;
					(* Like findchar, but search  *)
label 1;				(* backwards, and with the following *)
var ch: char; i: integer;		(* difference: start with the char  *)
begin					(* immediately preceding offset pos. *)
  for i:=pos-1 downto pos-range do begin
    ch:=getbyte(r,i);
    if ch=ch1 then goto 1;
    if ch=ch2 then goto 1
  end;
  i:=pos;
1:bfindchar:=pos-i
end;

(*@TOPS: begin end. *)
(*@VMS: end. *)
