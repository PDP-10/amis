(* AMIS main module. *)  (* -*-PASCAL-*- *)

(****************************************************************************)
(*									    *)
(*  Copyright (C) 1980, 1981, 1982, 1983, 1984, 1985, 1986, 1987 by	    *)
(*  Stacken, Royal Institute Of Technology, Stockholm, Sweden		    *)
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

(*$E+,T-,S4000 *)

module Main;

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

  HelpChar = CtrlUnderScore; (* Gives you help almost everywhere in AMIS.    *)

  StrSize = 40; (* Length of fixed length PACKED ARRAY OF CHAR strings.	     *)

(*@VMS:  DskSize = 512; *)	(* Size of disk block on VMS. *)
(*@TOPS: DskSize = 640; *)	(* Size of disk block on Tops-10. *)

  DskFatal = -2;		(* Error code for fatal disk errors. *)
  DskWarning = -1;		(* Error code for non-fatal disk errors. *)

  UndoRegister = -37;		(* The local Q-reg where we store undo text *)
  TempRegister = -38;		(* The local Q-reg we use as temp storage *)

  MarkSize = 7;			(* 8 marks in ring *)

  NoArgument = MaxInt;		(* Code for a missing argument. *)
 
  PushPoint = 500; (* Auto Push Point (set mark if search moves further). *)

type
 
  bufpos = integer;		(* Buffer position *)

  dskbp = ^dskblock;
  dskblock = packed array[1..DskSize] of char;  (* Disk block *)

  string = packed array[1..StrSize] of char; (* String *)

  setofchar = set of char;	(* Sigh... *)

  catchblock = record		(* Catch context block *)
    ProgramCounterNewPointer, FramePointer, StackPointer: integer;
   (*@VMS: ArgumentPointer: integer; *)
  end;

  majors = (FirstMajor,	(* Major modes *)
	FunMode,	TextMode,	AlgolMode,	MacroMode,
	PascalMode,	LispMode,	CMode,		TeXMode,
	AdaMode,	ModulaMode,	PL1Mode,	BlissMode,
	LastMajor);

  minors = (FirstMinor,	(* Minor modes *)
	FillMode,	SwedMode,	OvWMode,
	LastMinor);

  setofminors = set of minors;

  refname = ^namefilename;
  namefilename = record
    Left, Right	: refname;	(* Pointers in linked list *)
    Number	: integer;	(* Buffer number used by MAIN and BUFFER *)
    Name	: string;	(* Buffer name *)
    FileName	: string;	(* File visited in this buffer *)
    NoFileName	: boolean;	(* No file name, so use default *)
    ReadOnly	: boolean;	(* File is read only *)
    MajorMode	: majors;	(* Major mode *)
    MinorModes	: setofminors;	(* Minor modes *)
    MarkPos	: integer;	(* Current position in ring of marks *)
    MarkRing	: array[0..MarkSize] of bufpos; (* Ring of marks *)
  end;

  refmacro = ^kbdmacroblock;
  kbdmacroblock = packed record
    Next   : refmacro;		(* Pointer to next macro, or nil *)
    Number : integer;		(* Number used by INPUT module *)
    Name   : string;		(* Keybord macro name *)
  end;

  refcharassign = ^kbdcharassign;
  kbdcharassign = packed record
    Next : refcharassign;	(* Pointer to next assign, or nil *)
    Key  : integer;		(* Ord of seven or nine bit char assigned *)
    Code : refmacro;		(* Pointer to my macro name block *)
  end;

  linetype = (BlLine, BpLine, ParLine);

  fcode = (FFirst,		(* Function codes *)
	FAbort,		FAda,
	FAlgol,		FApropos,	FAutoFill,	FBlissMode,
	FCMode,		FCompileExit,	FConnect,
	FDateEdit,	FDescribe,	FDetach,
	FFindFile,	FFundamental,	FHackmatic,	FHowMany,
	FIndTabs,	FInsertBuffer,	FInsertDate,	FInsertFile,
	FKillBuffer,	FLispMode,	FListBuffers,	FListFiles,
	FListMatching,	FMacro,		FModula,	FKbdName,
	FOverWrite,	FPascal,	FPOM,		FPL1,
	FPushToExec,
	FQReplace,	FRenameBuffer,	FReplace,	FSelectBuffer,
	FSetEndComm,	FSetStartComm,	FSetFlags,	FSetIndentLevel,
	FSetKey,	FSetFileName,
	FStripSOSNum,	FSwedish,	FTabify,	FTeXMode,
	FText,		FUndo,		FUnTabify,	FViewFile,
	FKbdView,	FViewQRegister,	FWallChart,	FWhatCursorPos,
	FWhatDate,	FWhatPage,	FWhatVersion,	FWhereIs,
	FWriteFile,	FWriteRegion,	FXonXoff,	FAppendNextKill,
	FArgumentDigit,	FFillSpace,	FAutoArgument,
	FBackToIndent,	FBwdChar,	FBwdDelChar,	FBwdDelHackTab,
	FBwdKilWord,	FBwdKilSentence,FBwdList,	FBwdParagraph,
	FBwdSentence,	FBwdWord,	FBegLine,	FBufNotModified,
	FCenterLine,	FChrExtend,	FCopyRegion,	FCountLinesPage,
	FCrLf,		FDelBlankLines,	FDelChar,	FDelHorSpace,
	FDelIndentation,FCDescribe,
	FDocumentation,	FDownCommLine,	FDownLine,	FEndLine,
	FKbdEnd,	FExchange,	FKbdExecute,	FExit,
	FExtend,	FFillParagraph,	FFillRegion,
	FFwdChar,	FFwdList,	FFwdParagraph,	FFwdSentence,
	FFwdWord,	FGetQRegister,	FGoToBeg,	FGoToEnd,
	FGrowWindow,	FISearch,	FIndAlgol,	FIndAda,
	FIndBliss,
	FIndC,		FIndForComm,	FIndForLisp,	FIndModula,
	FIndNewComm,	FIndNewLine,	FIndPascal,	FIndPL1,
	FIndRegion,	FIndRigidly,	FIndSEXP,	FCSISequence,
	FVT100Pad,
	FKbdQuery,	FKillComment,	FKilLine,	FKillRegion,
	FKillSentence,	FKillWord,	FLowCaseReg,	FLowWord,
	FMakeParens,	FMarkBeg,	FMarkEnd,	FMarkPage,
	FMarkParagraph,	FMarkWhole,	FMarkWord,	FMoveToEdge,
	FNegArgument,
	FNewWindow,	FNextPage,	FNextScreen,	F1Window,
	FOtherWindow,	FOpenLine,	FPfxControl,	FPfxCM,
	FPfxMeta,	FPrevPage,	FPrevScreen,	FPutQRegister,
	FQuit,		FQInsert,	FReadFile,	FReturn,
	FRSearch,	FSaveFile,	FScrollOther,	FSelfInsert,
	FSetCommColumn,	FSetFillColumn,	FSetPrefixFill,	FSetPopMark,
	FKbdStart,	FSearch,	FToTabStop,
	FTrnChar,	FTrnLines,
	FTrnRegions,	FTrnWords,	F2Windows,	FUnKill,
	FUnKillPop,	FUnivArgument,	FUpCommLine,	FUpLine,
	FUpInitial,	FUpCaseReg,	FUpWord,
	FVisitFile,	FVisitInOther,
	FLast,
(**** The last four function codes are for internal use, only ****)
	FMacroExtend,		(* Used with M-X on Kbd macros *)
	FMacroCharacter,	(* Used with Kbd macro assigned to char. *)
	FUnUsed,		(* UUK? UnUsed Key *)
	FIllegal);		(* ILC? Illegal Command *)

  keyword = (FirstKeyword,
	KwACCEPT,
	KwBEGIN,
	KwCASE,
	KwCONST,
	KwDO,
	KwELSE,
	KwELSIF,
	KwEND,
	KwEXCEPTION,
	KwLOOP,
	KwPROCEDURE,
	KwRECORD,
	KwREPEAT,
	KwSELECT,
	KwTHEN,
	KwTYPE,
	KwUNTIL,
	KwVAR,
  LastKeyword);

  char7  = 0..127;		(* Seven bit ascii *)     
  char8  = 0..255;		(* Eight bit ascii *)
  char9  = 0..511;		(* Nine bit ascii *)
  char10 = 0..1023;		(* Ten bit ascii *)

  prefixes = (PfxMeta, PfxControl);

var
  ZeroName	: refname;	(* Name block of buffer 0 *)
  CurrName	: refname;	(* Name block of current buffer *)
  PrevName	: refname;	(* Name block of previous buffer *)
  OtherName	: refname;	(* Name block of other window's buffer *)
  UnKillMark	: bufpos;	(* Value of mark at last unkill *)
  UnKillDot	: bufpos;	(* Value of dot at last unkill *)
  UndoFunction	: fcode;	(* The function we can undo, if any *)
  UndoBuffer	: integer;	(* The buffer we can undo inside *)

  ArgArg	: integer;	(* The argument being typed in *)
  ArgExp4	: integer;	(* Argument exponent of four *)
  ArgSign	: -1..1;	(* The sign of the argument being typed *)
  ArgFlag	: boolean;	(* Typing of an argument is in progress *)
  ArgDigits	: boolean;	(* Argument digits have been typed in *)
  ArgKeep	: boolean;	(* The argument should be kept *)

  Prefix	: set of prefixes; (* Prefix of command *)

  DispTab	: array [char10] of fcode;
  CXTable	: array [char8] of fcode;
  VTTable	: array [char7] of fcode;
  TildeTable	: array [0..35] of fcode;

  LastKey	: char; 	(* The last key pressed *)
  LastTenBit	: char9;	(* The last nine bit character *)
  LastFunc	: fcode;	(* The last function executed *)

  ZeroMacro	: refmacro;	(* Head of the keybord macro list *)
  ZeroChar	: refcharassign;(* Head of kbd macro assign list *)
  KbdRecMacro	: refmacro;	(* Needed to get M-X to work on macro names *)

  TahStr1	: string;	(* Type-ahead string 1 for M-X args *)
  TahStr2	: string;	(* Type-ahead string 2 for M-X args *)
  TahFunction	: fcode;	(* Type ahead function code, if any such *)
  TahLen1	: integer;	(* Significant length of TahStr1 *)
  TahLen2	: integer;	(* Significant length of TahStr2 *)
  TahType	: (NoTahArg, OneTahArg, TwoTahArgs, TahFuncArg);

  FuncCount	: integer;	(* Count of functions executed *)
  KillIndex	: integer;	(* Count of last kill operation *)
  DownIndex	: integer;	(* Count of last up/down operation *)

  GoalColumn	: integer;	(* Goal column for up/down real line *)

  FuncName	: array[fcode] of string;	(* Function names *)

  KeyWName	: array[keyword] of string;	(* Keywords. *)

  Err		: catchblock;	(* The catch-block for ERROR *)
  RecExitFlag	: boolean;	(* Flag for time to exit edit level *)
  RecAbortFlag	: boolean;	(* Flag for abort instead of normal exit *)
  RecName	: string;	(* Name of recursive editing level *)
  RecLevel	: integer;	(* Number of active recursive levels *)

  BVoid		: boolean;	(* Used for voiding *)
  IVoid		: integer;	(* Used for voiding *)
  CVoid		: char;		(* Used for voiding *)

  ModeChanged	: boolean;	(* Flag for mode has changed *)
  MajorMode	: majors;	(* Current major mode *)
  MinorModes	: setofminors;	(* Current minor modes *)
  DefiningMacro	: boolean;	(* True if we are defining a macro *)

  MajorName	: array[majors] of string;	(* Major mode names *)
  MinorName	: array[minors] of string;	(* Minor mode names *)

  FillColumn	: integer;	(* Fill column for Auto Fill Mode *)
  FillPrefix	: string;	(* Fill prefix string *)
  FillPLength	: integer;	(* Length of fill prefix string *)

  Uppers	: set of char;	(* The current upper-case letters. *)
  Lowers	: set of char;	(* The current lower-case letters. *)
  Letters	: set of char;	(* The current letters, both cases. *)
  Alphas	: set of char;	(* Current non-delimiters. *)
  LParens	: set of char;	(* Set of left parens in current mode. *)
  RParens	: set of char;	(* Set of right parens in current mode. *)
  Quotes	: set of char;	(* Set of string quotes in current mode. *)

  Indenters	: array [majors] of set of keyword;
  Exdenters	: array [majors] of set of keyword;

  BlockILevel	: integer;	(* How much to indent code inside a block *)
  HackmaticMode	: boolean;	(* True if we are using meta keys *)
  UsingXonXoff	: boolean;	(* True if using XonXoff as flow control *)
  UsingTabs	: Boolean;	(* Using TABs for indentation? *)
  Antique	: boolean;	(* Old (EMACS) or new (GNUMACS) style. *)

  CommColumn	: array [majors] of integer;	(* Comment columns *)
  CBeginString	: array [majors] of string;	(* Comment begin string *)
  CBeginLength	: array [majors] of integer;	(* Comment begin length *)
  CEndString	: array [majors] of string;	(* Comment end string *)
  CEndLength	: array [majors] of integer;	(* Comment end length *)

  TabTable	: array [majors] of fcode;	(* Tab function. *)
  RubTable	: array [majors] of fcode;	(* Rubout function. *)

(*@VMS: [initialize] procedure *)
initprocedure;
begin				(* Here we initialize static data *)
  FuncName[FAbort] :=		'Abort Recursive Edit                    ';
  FuncName[FAda] :=		'ADA Mode                                ';
  FuncName[FAlgol] :=		'ALGOL Mode                              ';
  FuncName[FApropos] :=		'Apropos                                 ';
  FuncName[FAutoFill] :=	'Auto Fill Mode                          ';
  FuncName[FBlissMode] :=	'BLISS Mode                              ';
  FuncName[FCMode] :=		'C Mode                                  ';
  FuncName[FCompileExit] :=	'Compile                                 ';
  FuncName[FConnect] :=		'Connect to Directory                    ';
  FuncName[FDateEdit] :=	'Date Edit                               ';
  FuncName[FDescribe] :=	'Describe                                ';
  FuncName[FDetach] :=		'Detach                                  ';
  FuncName[FFindFile] :=	'Find File                               ';
  FuncName[FFundamental] :=	'Fundamental Mode                        ';
  FuncName[FHackmatic] :=	'Hackmatic Terminal                      ';
  FuncName[FHowMany] :=		'How Many                                ';
  FuncName[FIndTabs] :=		'Indent Tabs Mode                        ';
  FuncName[FInsertBuffer] :=	'Insert Buffer                           ';
  FuncName[FInsertDate] :=	'Insert Date                             ';
  FuncName[FInsertFile] :=	'Insert File                             ';
  FuncName[FKillBuffer] :=	'Kill Buffer                             ';
  FuncName[FLispMode] :=	'LISP Mode                               ';
  FuncName[FListBuffers] :=	'List Buffers                            ';
  FuncName[FListFiles] :=	'List Files                              ';
  FuncName[FListMatching] :=	'List Matching Lines                     ';
  FuncName[FMacro] :=		'MACRO Mode                              ';
  FuncName[FModula] :=		'Modula-2 Mode                           ';
  FuncName[FKbdName] :=		'Name Kbd Macro                          ';
  FuncName[FOverWrite] :=	'Overwrite Mode                          ';
  FuncName[FPascal] :=		'PASCAL Mode                             ';
  FuncName[FPOM] :=		'Phase Of Moon                           ';
  FuncName[FPL1] :=		'PL/1 Mode                               ';
  FuncName[FPushToExec] :=	'Push to EXEC                            ';
  FuncName[FQReplace] :=	'Query Replace                           ';
  FuncName[FRenameBuffer] :=	'Rename Buffer                           ';
  FuncName[FReplace] :=		'Replace String                          ';
  FuncName[FSelectBuffer] :=	'Select Buffer                           ';
  FuncName[FSetEndComm] :=	'Set Comment End                         ';
  FuncName[FSetStartComm] :=	'Set Comment Start                       ';
  FuncName[FSetIndentLevel] :=	'Set Indent Level                        ';
  FuncName[FSetFlags] :=	'Set Flags                               ';
  FuncName[FSetKey] :=		'Set Key                                 ';
  FuncName[FSetFileName] :=	'Set Visited File Name                   ';
  FuncName[FStripSOSNum] :=	'Strip SOS Line Numbers                  ';
  FuncName[FSwedish] :=		'Swedish Mode                            ';
  FuncName[FTabify] :=		'Tabify                                  ';
  FuncName[FTeXMode] :=		'TeX Mode                                ';
  FuncName[FText] :=		'Text Mode                               ';
  Funcname[FUndo] :=		'Undo                                    ';
  FuncName[FUnTabify] :=	'Untabify                                ';
  FuncName[FViewFile] :=	'View File                               ';
  FuncName[FKbdView] :=		'View Kbd Macro                          ';
  FuncName[FViewQRegister] :=	'View Q-register                         ';
  FuncName[FWallChart] :=	'Wall Chart                              ';
  FuncName[FWhatCursorPos] :=	'What Cursor Position                    ';
  FuncName[FWhatDate] :=	'What Date                               ';
  FuncName[FWhatPage] :=	'What Page                               ';
  FuncName[FWhatVersion] :=	'What Version                            ';
  FuncName[FWhereIs] :=		'Where Is                                ';
  FuncName[FWriteFile] :=	'Write File                              ';
  FuncName[FWriteRegion] :=	'Write Region                            ';
  FuncName[FXonXoff] :=		'XonXoff mode                            ';
  FuncName[FAppendNextKill] :=	'^R Append Next Kill                     ';
  FuncName[FArgumentDigit] :=	'^R Argument Digit                       ';
  FuncName[FFillSpace] :=	'^R Auto-Fill Space                      ';
  FuncName[FAutoArgument] :=	'^R Autoargument                         ';
  FuncName[FBackToIndent] :=	'^R Back to Indentation                  ';
  FuncName[FBwdChar] :=		'^R Backward Character                   ';
  FuncName[FBwdDelChar] :=	'^R Backward Delete Character            ';
  FuncName[FBwdDelHackTab] :=	'^R Backward Delete Hacking Tabs         ';
  FuncName[FBwdKilWord] :=	'^R Backward Kill Word                   ';
  FuncName[FBwdKilSentence] :=	'^R Backward Kill Sentence               ';
  FuncName[FBwdList] :=		'^R Backward List                        ';
  FuncName[FBwdParagraph] :=	'^R Backward Paragraph                   ';
  FuncName[FBwdSentence] :=	'^R Backward Sentence                    ';
  FuncName[FBwdWord] :=		'^R Backward Word                        ';
  FuncName[FBegLine] :=		'^R Beginning of Line                    ';
  FuncName[FBufNotModified] :=	'^R Buffer Not Modified                  ';
  FuncName[FCenterLine] :=	'^R Center Line                          ';
  FuncName[FChrExtend] :=	'^R Character Extend                     ';
  FuncName[FCopyRegion] :=	'^R Copy Region                          ';
  FuncName[FCountLinesPage] :=	'^R Count Lines Page                     ';
  FuncName[FCrLf] :=		'^R CRLF                                 ';
  FuncName[FDelBlankLines] :=	'^R Delete Blank Lines                   ';
  FuncName[FDelChar] :=		'^R Delete Character                     ';
  FuncName[FDelHorSpace] :=	'^R Delete Horizontal Space              ';
  FuncName[FDelIndentation] :=	'^R Delete Indentation                   ';
  FuncName[FCDescribe] :=	'^R Describe                             ';
  FuncName[FDocumentation] :=	'^R Documentation                        ';
  FuncName[FDownCommLine] :=	'^R Down Comment Line                    ';
  FuncName[FDownLine] :=	'^R Down Real Line                       ';
  FuncName[FEndLine] :=		'^R End of Line                          ';
  FuncName[FKbdEnd] :=		'^R End Kbd Macro                        ';
  FuncName[FExchange] :=	'^R Exchange Point and Mark              ';
  FuncName[FKbdExecute] :=	'^R Execute Kbd Macro                    ';
  FuncName[FExit] :=		'^R Exit                                 ';
  FuncName[FExtend] :=		'^R Extended Command                     ';
  FuncName[FFillParagraph] :=	'^R Fill Paragraph                       ';
  FuncName[FFillRegion] :=	'^R Fill Region                          ';
  FuncName[FFwdChar] :=		'^R Forward Character                    ';
  FuncName[FFwdList] :=		'^R Forward List                         ';
  FuncName[FFwdParagraph] :=	'^R Forward Paragraph                    ';
  FuncName[FFwdSentence] :=	'^R Forward Sentence                     ';
  FuncName[FFwdWord] :=		'^R Forward Word                         ';
  FuncName[FGetQRegister] :=	'^R Get Q-reg                            ';
  FuncName[FGoToBeg] :=		'^R Goto Beginning                       ';
  FuncName[FGoToEnd] :=		'^R Goto End                             ';
  FuncName[FGrowWindow] :=	'^R Grow Window                          ';
  FuncName[FISearch] :=		'^R Incremental Search                   ';
  FuncName[FIndAlgol] :=	'^R Indent Algol Stm                     ';
  FuncName[FIndAda] :=		'^R Indent ADA Stm                       ';
  FuncName[FIndBliss] :=	'^R Indent BLISS stm                     ';
  FuncName[FIndC] :=		'^R Indent C stm                         ';
  FuncName[FIndForComm] :=	'^R Indent For Comment                   ';
  FuncName[FIndForLisp] :=	'^R Indent For LISP                      ';
  FuncName[FIndModula] :=	'^R Indent Modula-2 Stm                  ';
  FuncName[FIndNewComm] :=	'^R Indent New Comment Line              ';
  FuncName[FIndNewLine] :=	'^R Indent New Line                      ';
  FuncName[FIndPascal] :=	'^R Indent Pascal Stm                    ';
  FuncName[FIndPL1] :=		'^R Indent PL/1 Stm                      ';
  FuncName[FIndRegion] :=	'^R Indent Region                        ';
  FuncName[FIndRigidly] :=	'^R Indent Rigidly                       ';
  FuncName[FIndSEXP] :=		'^R Indent SEXP                          ';
  FuncName[FCSISequence] :=	'^R Interpret CSI Sequence               ';
  FuncName[FVT100Pad] :=	'^R Interpret VT100 Keypad               ';
  FuncName[FKbdQuery] :=	'^R Kbd Macro Query                      ';
  FuncName[FKillComment] :=	'^R Kill Comment                         ';
  FuncName[FKilLine] :=		'^R Kill Line                            ';
  FuncName[FKillRegion] :=	'^R Kill Region                          ';
  FuncName[FKillSentence] :=	'^R Kill Sentence                        ';
  FuncName[FKillWord] :=	'^R Kill Word                            ';
  FuncName[FLowCaseReg] :=	'^R Lowercase Region                     ';
  FuncName[FLowWord] :=		'^R Lowercase Word                       ';
  FuncName[FMakeParens] :=	'^R Make ()                              ';
  FuncName[FMarkBeg] :=		'^R Mark Beginning                       ';
  FuncName[FMarkEnd] :=		'^R Mark End                             ';
  FuncName[FMarkPage] :=	'^R Mark Page                            ';
  FuncName[FMarkParagraph] :=	'^R Mark Paragraph                       ';
  FuncName[FMarkWhole] :=	'^R Mark Whole Buffer                    ';
  FuncName[FMarkWord] :=	'^R Mark Word                            ';
  FuncName[FMoveToEdge] :=	'^R Move to Screen Edge                  ';
  FuncName[FNegArgument] :=	'^R Negative Argument                    ';
  FuncName[FNewWindow] :=	'^R New Window                           ';
  FuncName[FNextPage] :=	'^R Next Page                            ';
  FuncName[FNextScreen] :=	'^R Next Screen                          ';
  FuncName[F1Window] :=		'^R One Window                           ';
  FuncName[FOtherWindow] :=	'^R Other Window                         ';
  FuncName[FOpenLine] :=	'^R Open Line                            ';
  FuncName[FPfxControl] :=	'^R Prefix Control                       ';
  FuncName[FPfxCM] :=		'^R Prefix Control-Meta                  ';
  FuncName[FPfxMeta] :=		'^R Prefix Meta                          ';
  FuncName[FPrevPage] :=	'^R Previous Page                        ';
  FuncName[FPrevScreen] :=	'^R Previous Screen                      ';
  FuncName[FPutQRegister] :=	'^R Put Q-reg                            ';
  FuncName[FQuit] :=		'^R Quit                                 ';
  FuncName[FQInsert] :=		'^R Quoted Insert                        ';
  FuncName[FReadFile] :=	'^R Read File                            ';
  FuncName[FReturn] :=		'^R Return to Superior                   ';
  FuncName[FRSearch] :=		'^R Reverse Search                       ';
  FuncName[FSaveFile] :=	'^R Save File                            ';
  FuncName[FScrollOther] :=	'^R Scroll Other Window                  ';
  FuncName[FSelfInsert] :=	'^R Self Insert                          ';
  FuncName[FSetCommColumn] :=	'^R Set Comment Column                   ';
  FuncName[FSetFillColumn] :=	'^R Set Fill Column                      ';
  FuncName[FSetPrefixFill] :=	'^R Set Fill Prefix                      ';
  FuncName[FSetPopMark] :=	'^R Set/Pop Mark                         ';
  FuncName[FKbdStart] :=	'^R Start Kbd Macro                      ';
  FuncName[FSearch] :=		'^R String Search                        ';
  FuncName[FToTabStop] :=	'^R Tab to Tab Stop                      ';
  FuncName[FTrnChar] :=		'^R Transpose Characters                 ';
  FuncName[FTrnLines] :=	'^R Transpose Lines                      ';
  FuncName[FTrnRegions] :=	'^R Transpose Regions                    ';
  FuncName[FTrnWords] :=	'^R Transpose Words                      ';
  FuncName[F2Windows] :=	'^R Two Windows                          ';
  FuncName[FUnKill] :=		'^R Un-kill                              ';
  FuncName[FUnKillPop] :=	'^R Un-kill pop                          ';
  FuncName[FUnivArgument] :=	'^R Universal Argument                   ';
  FuncName[FUpCommLine] :=	'^R Up Comment Line                      ';
  FuncName[FUpLine] :=		'^R Up Real Line                         ';
  FuncName[FUpInitial] :=	'^R Uppercase Initial                    ';
  FuncName[FUpCaseReg] :=	'^R Uppercase Region                     ';
  FuncName[FUpWord] :=		'^R Uppercase Word                       ';
  FuncName[FVisitFile] :=	'^R Visit File                           ';
  FuncName[FVisitInOther] :=	'^R Visit in Other Window                ';

  KeyWName[KwACCEPT] :=		'ACCEPT                                  ';
  KeyWName[KwBEGIN] :=		'BEGIN                                   ';
  KeyWName[KwCASE] :=		'CASE                                    ';
  KeyWName[KwCONST] :=		'CONST                                   ';
  KeyWName[KwDO] :=		'DO                                      ';
  KeyWName[KwELSE] :=		'ELSE                                    ';
  KeyWName[KwELSIF] :=		'ELSIF                                   ';
  KeyWName[KwEND] :=		'END                                     ';
  KeyWName[KwEXCEPTION] :=	'EXCEPTION                               ';
  KeyWName[KwLOOP] :=		'LOOP                                    ';
  KeyWName[KwPROCEDURE] :=	'PROCEDURE                               ';
  KeyWName[KwRECORD] :=		'RECORD                                  ';
  KeyWName[KwREPEAT] :=		'REPEAT                                  ';
  KeyWName[KwSELECT] :=		'SELECT                                  ';
  KeyWName[KwTHEN] :=		'THEN                                    ';
  KeyWName[KwTYPE] :=		'TYPE                                    ';
  KeyWName[KwUNTIL] :=		'UNTIL                                   ';
  KeyWName[KwVAR] :=		'VAR                                     ';

  DispTab[0]	:= FIllegal;		(* ^@ *)
  DispTab[1]	:= FIllegal;		(* ^A *)
  DispTab[2]	:= FIllegal;		(* ^B *)
  DispTab[3]	:= FIllegal;		(* ^C *)
  DispTab[4]	:= FIllegal;		(* ^D *)
  DispTab[5]	:= FIllegal;		(* ^E *)
  DispTab[6]	:= FIllegal;		(* ^F *)
  DispTab[7]	:= FIllegal;		(* ^G *)
  DispTab[8]	:= FBwdChar;		(* Backspace *)
  DispTab[9]	:= FToTabStop;		(* Tab *)
  DispTab[10]	:= FIndNewLine;		(* Linefeed *)
  DispTab[11]	:= FIllegal;		(* ^K *)
  DispTab[12]	:= FIllegal;		(* ^L *)
  DispTab[13]	:= FCrLf;		(* Return *)
  DispTab[14]	:= FIllegal;		(* ^N *)
  DispTab[15]	:= FIllegal;		(* ^O *)
  DispTab[16]	:= FIllegal;		(* ^P *)
  DispTab[17]	:= FIllegal;		(* ^Q *)
  DispTab[18]	:= FIllegal;		(* ^R *)
  DispTab[19]	:= FIllegal;		(* ^S *)
  DispTab[20]	:= FIllegal;		(* ^T *)
  DispTab[21]	:= FIllegal;		(* ^U *)
  DispTab[22]	:= FIllegal;		(* ^V *)
  DispTab[23]	:= FIllegal;		(* ^W *)
  DispTab[24]	:= FIllegal;		(* ^X *)
  DispTab[25]	:= FIllegal;		(* ^Y *)
  DispTab[26]	:= FIllegal;		(* ^Z *)
  DispTab[27]	:= FPfxMeta;		(* Escape *)
  DispTab[28]	:= FIllegal;		(* ^Backslash *)
  DispTab[29]	:= FIllegal;		(* ^] *)
  DispTab[30]	:= FIllegal;		(* ^^ *)
  DispTab[31]	:= FIllegal;		(* ^_ *)
  DispTab[32]	:= FSelfInsert;		(* Space *)
  DispTab[33]	:= FSelfInsert;		(* ! *)
  DispTab[34]	:= FSelfInsert;		(* " *)
  DispTab[35]	:= FSelfInsert;		(* # *)
  DispTab[36]	:= FSelfInsert;		(* $ *)
  DispTab[37]	:= FSelfInsert;		(* % *)
  DispTab[38]	:= FSelfInsert;		(* & *)
  DispTab[39]	:= FSelfInsert;		(* ' *)
  DispTab[40]	:= FSelfInsert;		(* ( *)
  DispTab[41]	:= FSelfInsert;		(* ) *)
  DispTab[42]	:= FSelfInsert;		(* * *)
  DispTab[43]	:= FSelfInsert;		(* + *)
  DispTab[44]	:= FSelfInsert;		(* , *)
  DispTab[45]	:= FSelfInsert;		(* - *)
  DispTab[46]	:= FSelfInsert;		(* . *)
  DispTab[47]	:= FSelfInsert;		(* / *)
  DispTab[48]	:= FSelfInsert;		(* 0 *)
  DispTab[49]	:= FSelfInsert;		(* 1 *)
  DispTab[50]	:= FSelfInsert;		(* 2 *)
  DispTab[51]	:= FSelfInsert;		(* 3 *)
  DispTab[52]	:= FSelfInsert;		(* 4 *)
  DispTab[53]	:= FSelfInsert;		(* 5 *)
  DispTab[54]	:= FSelfInsert;		(* 6 *)
  DispTab[55]	:= FSelfInsert;		(* 7 *)
  DispTab[56]	:= FSelfInsert;		(* 8 *)
  DispTab[57]	:= FSelfInsert;		(* 9 *)
  DispTab[58]	:= FSelfInsert;		(* : *)
  DispTab[59]	:= FSelfInsert;		(* ; *)
  DispTab[60]	:= FSelfInsert;		(* < *)
  DispTab[61]	:= FSelfInsert;		(* = *)
  DispTab[62]	:= FSelfInsert;		(* > *)
  DispTab[63]	:= FSelfInsert;		(* ? *)
  DispTab[64]	:= FSelfInsert;		(* @ *)
  DispTab[65]	:= FSelfInsert;		(* A *)
  DispTab[66]	:= FSelfInsert;		(* B *)
  DispTab[67]	:= FSelfInsert;		(* C *)
  DispTab[68]	:= FSelfInsert;		(* D *)
  DispTab[69]	:= FSelfInsert;		(* E *)
  DispTab[70]	:= FSelfInsert;		(* F *)
  DispTab[71]	:= FSelfInsert;		(* G *)
  DispTab[72]	:= FSelfInsert;		(* H *)
  DispTab[73]	:= FSelfInsert;		(* I *)
  DispTab[74]	:= FSelfInsert;		(* J *)
  DispTab[75]	:= FSelfInsert;		(* K *)
  DispTab[76]	:= FSelfInsert;		(* L *)
  DispTab[77]	:= FSelfInsert;		(* M *)
  DispTab[78]	:= FSelfInsert;		(* N *)
  DispTab[79]	:= FSelfInsert;		(* O *)
  DispTab[80]	:= FSelfInsert;		(* P *)
  DispTab[81]	:= FSelfInsert;		(* Q *)
  DispTab[82]	:= FSelfInsert;		(* R *)
  DispTab[83]	:= FSelfInsert;		(* S *)
  DispTab[84]	:= FSelfInsert;		(* T *)
  DispTab[85]	:= FSelfInsert;		(* U *)
  DispTab[86]	:= FSelfInsert;		(* V *)
  DispTab[87]	:= FSelfInsert;		(* W *)
  DispTab[88]	:= FSelfInsert;		(* X *)
  DispTab[89]	:= FSelfInsert;		(* Y *)
  DispTab[90]	:= FSelfInsert;		(* Z *)
  DispTab[91]	:= FSelfInsert;		(* [ *)
  DispTab[92]	:= FSelfInsert;		(* Backslash *)
  DispTab[93]	:= FSelfInsert;		(* ] *)
  DispTab[94]	:= FSelfInsert;		(* ^ *)
  DispTab[95]	:= FSelfInsert;		(* _ *)
  DispTab[96]	:= FSelfInsert;		(* ` *)
  DispTab[97]	:= FSelfInsert;		(* a *)
  DispTab[98]	:= FSelfInsert;		(* b *)
  DispTab[99]	:= FSelfInsert;		(* c *)
  DispTab[100]	:= FSelfInsert;		(* d *)
  DispTab[101]	:= FSelfInsert;		(* e *)
  DispTab[102]	:= FSelfInsert;		(* f *)
  DispTab[103]	:= FSelfInsert;		(* g *)
  DispTab[104]	:= FSelfInsert;		(* h *)
  DispTab[105]	:= FSelfInsert;		(* i *)
  DispTab[106]	:= FSelfInsert;		(* j *)
  DispTab[107]	:= FSelfInsert;		(* k *)
  DispTab[108]	:= FSelfInsert;		(* l *)
  DispTab[109]	:= FSelfInsert;		(* m *)
  DispTab[110]	:= FSelfInsert;		(* n *)
  DispTab[111]	:= FSelfInsert;		(* o *)
  DispTab[112]	:= FSelfInsert;		(* p *)
  DispTab[113]	:= FSelfInsert;		(* q *)
  DispTab[114]	:= FSelfInsert;		(* r *)
  DispTab[115]	:= FSelfInsert;		(* s *)
  DispTab[116]	:= FSelfInsert;		(* t *)
  DispTab[117]	:= FSelfInsert;		(* u *)
  DispTab[118]	:= FSelfInsert;		(* v *)
  DispTab[119]	:= FSelfInsert;		(* w *)
  DispTab[120]	:= FSelfInsert;		(* x *)
  DispTab[121]	:= FSelfInsert;		(* y *)
  DispTab[122]	:= FSelfInsert;		(* z *)
  DispTab[123]	:= FSelfInsert;		(* { *)
  DispTab[124]	:= FSelfInsert;		(* | *)
  DispTab[125]	:= FSelfInsert;		(* RightBrace *)
  DispTab[126]	:= FSelfInsert;		(* ~ *)
  DispTab[127]	:= FBwdDelChar;		(* Rubout *)	(* standard ASCII *)

  DispTab[128]	:= FIllegal;		(*  *)		(* 8 *)
  DispTab[129]	:= FIllegal;		(*  *)
  DispTab[130]	:= FIllegal;		(*  *)
  DispTab[131]	:= FIllegal;		(*  *)
  DispTab[132]	:= FIllegal;		(* IND *)
  DispTab[133]	:= FIllegal;		(* NEL *)
  DispTab[134]	:= FIllegal;		(* SSA *)
  DispTab[135]	:= FIllegal;		(* ESA *)
  DispTab[136]	:= FIllegal;		(* HTS *)
  DispTab[137]	:= FIllegal;		(* HTJ *)
  DispTab[138]	:= FIllegal;		(* VTS *)
  DispTab[139]	:= FIllegal;		(* PLD *)
  DispTab[140]	:= FIllegal;		(* PLU *)
  DispTab[141]	:= FIllegal;		(* RI *)
  DispTab[142]	:= FIllegal;		(* SS2 *)
  DispTab[143]	:= FVT100Pad;		(* SS3 (may be sent for Esc-O) *)
  DispTab[144]	:= FIllegal;		(* DCS *)
  DispTab[145]	:= FIllegal;		(* PU1 *)
  DispTab[146]	:= FIllegal;		(* PU2 *)
  DispTab[147]	:= FIllegal;		(* STS *)
  DispTab[148]	:= FIllegal;		(* CCH *)
  DispTab[149]	:= FIllegal;		(* MW *)
  DispTab[150]	:= FIllegal;		(* SPA *)
  DispTab[151]	:= FIllegal;		(* EPA *)
  DispTab[152]	:= FIllegal;		(*  *)
  DispTab[153]	:= FIllegal;		(*  *)
  DispTab[154]	:= FIllegal;		(*  *)
  DispTab[155]	:= FCSISequence;	(* CSI  (may be sent for Esc-[) *)
  DispTab[156]	:= FIllegal;		(* ST *)
  DispTab[157]	:= FIllegal;		(* OSC *)
  DispTab[158]	:= FIllegal;		(* PM *)
  DispTab[159]	:= FIllegal;		(* APC *)
  DispTab[160]	:= FSelfInsert;		(* No-Break Space *)
  DispTab[161]	:= FSelfInsert;		(* Inverse ! *)
  DispTab[162]	:= FselfInsert;		(* cent sign *)
  DispTab[163]	:= FselfInsert;		(* pound sign *)
  DispTab[164]	:= FSelfInsert;		(* Currency sign *)
  DispTab[165]	:= FselfInsert;		(* Yen sign *)
  DispTab[166]	:= FSelfInsert;		(* Broken bar *)
  DispTab[167]	:= FselfInsert;		(* Paragraph sign *)
  DispTab[168]	:= FSelfInsert;		(* Diaeresis *)
  DispTab[169]	:= FSelfInsert;		(* (C) *)
  DispTab[170]	:= FSelfInsert;		(* fem. ordinal *)
  DispTab[171]	:= FSelfInsert;		(* << *)
  DispTab[172]	:= FSelfInsert;		(* Not sign. *)
  DispTab[173]	:= FSelfInsert;		(* Soft hyphen *)
  DispTab[174]	:= FSelfInsert;		(* (R) *)
  DispTab[175]	:= FSelfInsert;		(* Macron, bar *)
  DispTab[176]	:= FSelfInsert;		(* degree *)
  DispTab[177]	:= FSelfInsert;		(* +- *)
  DispTab[178]	:= FSelfInsert;		(* super 2 *)
  DispTab[179]	:= FSelfInsert;		(* super 3 *)
  DispTab[180]	:= FSelfInsert;		(* Acute accent *)
  DispTab[181]	:= FSelfInsert;		(* Micro sign *)
  DispTab[182]	:= FSelfInsert;		(* pilcrow sign *)
  DispTab[183]	:= FSelfInsert;		(* center dot *)
  DispTab[184]	:= FSelfInsert;		(* Cedilla *)
  DispTab[185]	:= FSelfInsert;		(* Super 1 *)
  DispTab[186]	:= FSelfInsert;		(* male ordinal *)
  DispTab[187]	:= FSelfInsert;		(* >> *)
  DispTab[188]	:= FSelfInsert;		(* 1/4 *)
  DispTab[189]	:= FSelfInsert;		(* 1/2 *)
  DispTab[190]	:= FSelfInsert;		(* 3/4 *)
  DispTab[191]	:= FSelfInsert;		(* inverse ? *)
  DispTab[192]	:= FSelfInsert;		(* A` *)
  DispTab[193]	:= FSelfInsert;		(* A' *)
  DispTab[194]	:= FSelfInsert;		(* A^ *)
  DispTab[195]	:= FSelfInsert;		(* A~ *)
  DispTab[196]	:= FSelfInsert;		(* A"  *)
  DispTab[197]	:= FSelfInsert;		(* A* *)
  DispTab[198]	:= FSelfInsert;		(* AE *)
  DispTab[199]	:= FSelfInsert;		(* C, *)
  DispTab[200]	:= FSelfInsert;		(* E` *)
  DispTab[201]	:= FSelfInsert;		(* E' *)
  DispTab[202]	:= FSelfInsert;		(* E^ *)
  DispTab[203]	:= FSelfInsert;		(* E" *)
  DispTab[204]	:= FSelfInsert;		(* I` *)
  DispTab[205]	:= FSelfInsert;		(* I' *)
  DispTab[206]	:= FSelfInsert;		(* I^ *)
  DispTab[207]	:= FSelfInsert;		(* I" *)
  DispTab[208]	:= FSelfInsert;		(* D- *)
  DispTab[209]	:= FSelfInsert;		(* N~ *)
  DispTab[210]	:= FSelfInsert;		(* O` *)
  DispTab[211]	:= FSelfInsert;		(* O' *)
  DispTab[212]	:= FSelfInsert;		(* O^ *)
  DispTab[213]	:= FSelfInsert;		(* O~ *)
  DispTab[214]	:= FSelfInsert;		(* O" *)
  DispTab[215]	:= FSelfInsert;		(* Multiplication *)
  DispTab[216]	:= FSelfInsert;		(* O/ *)
  DispTab[217]	:= FSelfInsert;		(* U` *)
  DispTab[218]	:= FSelfInsert;		(* U' *)
  DispTab[219]	:= FSelfInsert;		(* U^ *)
  DispTab[220]	:= FSelfInsert;		(* U" *)
  DispTab[221]	:= FSelfInsert;		(* Y' *)
  DispTab[222]	:= FSelfInsert;		(* Capital thorn *)
  DispTab[223]	:= FSelfInsert;		(* ss *)
  DispTab[224]	:= FSelfInsert;		(* a` *)
  DispTab[225]	:= FSelfInsert;		(* a' *)
  DispTab[226]	:= FSelfInsert;		(* a^ *)
  DispTab[227]	:= FSelfInsert;		(* a~ *)
  DispTab[228]	:= FSelfInsert;		(* a" *)
  DispTab[229]	:= FSelfInsert;		(* a* *)
  DispTab[230]	:= FSelfInsert;		(* ae *)
  DispTab[231]	:= FSelfInsert;		(* c, *)
  DispTab[232]	:= FSelfInsert;		(* e` *)
  DispTab[233]	:= FSelfInsert;		(* e' *)
  DispTab[234]	:= FSelfInsert;		(* e^ *)
  DispTab[235]	:= FSelfInsert;		(* e" *)
  DispTab[236]	:= FSelfInsert;		(* i` *)
  DispTab[237]	:= FSelfInsert;		(* i' *)
  DispTab[238]	:= FSelfInsert;		(* i^ *)
  DispTab[239]	:= FSelfInsert;		(* i" *)
  DispTab[240]	:= FSelfInsert;		(* d- *)
  DispTab[241]	:= FSelfInsert;		(* n~ *)
  DispTab[242]	:= FSelfInsert;		(* o` *)
  DispTab[243]	:= FSelfInsert;		(* o' *)
  DispTab[244]	:= FSelfInsert;		(* o^ *)
  DispTab[245]	:= FSelfInsert;		(* o~ *)
  DispTab[246]	:= FSelfInsert;		(* o" *)
  DispTab[247]	:= FSelfInsert;		(* oe *)
  DispTab[248]	:= FSelfInsert;		(* o/ *)
  DispTab[249]	:= FSelfInsert;		(* u` *)
  DispTab[250]	:= FSelfInsert;		(* u' *)
  DispTab[251]	:= FSelfInsert;		(* u^ *)
  DispTab[252]	:= FSelfInsert;		(* u" *)
  DispTab[253]	:= FSelfInsert;		(* y' *)
  DispTab[254]	:= FSelfInsert;		(* lowercase thorn *)
  DispTab[255]	:= FSelfInsert;		(* y" *)	(* 8 *)

  DispTab[256]	:= FIllegal;		(* M-^@ *)	(* M- *)
  DispTab[257]	:= FIllegal;		(* M-^A *)
  DispTab[258]	:= FIllegal;		(* M-^B *)
  DispTab[259]	:= FIllegal;		(* M-^C *)
  DispTab[260]	:= FIllegal;		(* M-^D *)
  DispTab[261]	:= FIllegal;		(* M-^E *)
  DispTab[262]	:= FIllegal;		(* M-^F *)
  DispTab[263]	:= FIllegal;		(* M-^G *)
  DispTab[264]	:= FIllegal;		(* M-Backspace *)
  DispTab[265]	:= FIllegal;		(* M-Tab *)
  DispTab[266]	:= FIndNewComm;		(* M-Linefeed *)
  DispTab[267]	:= FIllegal;		(* M-^K *)
  DispTab[268]	:= FIllegal;		(* M-^L *)
  DispTab[269]	:= FBackToIndent;	(* M-Return *)
  DispTab[270]	:= FIllegal;		(* M-^N *)
  DispTab[271]	:= FIllegal;		(* M-^O *)
  DispTab[272]	:= FIllegal;		(* M-^P *)
  DispTab[273]	:= FIllegal;		(* M-^Q *)
  DispTab[274]	:= FIllegal;		(* M-^R *)
  DispTab[275]	:= FIllegal;		(* M-^S *)
  DispTab[276]	:= FIllegal;		(* M-^T *)
  DispTab[277]	:= FIllegal;		(* M-^U *)
  DispTab[278]	:= FIllegal;		(* M-^V *)
  DispTab[279]	:= FIllegal;		(* M-^W *)
  DispTab[280]	:= FIllegal;		(* M-^X *)
  DispTab[281]	:= FIllegal;		(* M-^Y *)
  DispTab[282]	:= FIllegal;		(* M-^Z *)
  DispTab[283]	:= FIllegal;		(* M-Escape *)
  DispTab[284]	:= FIllegal;		(* M-^Backslash *)
  DispTab[285]	:= FIllegal;		(* M-^] *)
  DispTab[286]	:= FIllegal;		(* M-^^ *)
  DispTab[287]	:= FIllegal;		(* M-^_ *)
  DispTab[288]	:= FIllegal;		(* M-Space *)
  DispTab[289]	:= FIllegal;		(* M-! *)
  DispTab[290]	:= FIllegal;		(* M-" *)
  DispTab[291]	:= FIllegal;		(* M-# *)
  DispTab[292]	:= FIllegal;		(* M-$ *)
  DispTab[293]	:= FQreplace;		(* M-% *)
  DispTab[294]	:= FIllegal;		(* M-& *)
  DispTab[295]	:= FIllegal;		(* M-' *)
  DispTab[296]	:= FMakeParens;		(* M-( *)
  DispTab[297]	:= FIllegal;		(* M-) *)
  DispTab[298]	:= FIllegal;		(* M-* *)
  DispTab[299]	:= FIllegal;		(* M-+ *)
  DispTab[300]	:= FIllegal;		(* M-, *)
  DispTab[301]	:= FAutoArgument;	(* M-- *)
  DispTab[302]	:= FIllegal;		(* M-. *)
  DispTab[303]	:= FCDescribe;		(* M-/ *)
  DispTab[304]	:= FAutoArgument;	(* M-0 *)
  DispTab[305]	:= FAutoArgument;	(* M-1 *)
  DispTab[306]	:= FAutoArgument;	(* M-2 *)
  DispTab[307]	:= FAutoArgument;	(* M-3 *)
  DispTab[308]	:= FAutoArgument;	(* M-4 *)
  DispTab[309]	:= FAutoArgument;	(* M-5 *)
  DispTab[310]	:= FAutoArgument;	(* M-6 *)
  DispTab[311]	:= FAutoArgument;	(* M-7 *)
  DispTab[312]	:= FAutoArgument;	(* M-8 *)
  DispTab[313]	:= FAutoArgument;	(* M-9 *)
  DispTab[314]	:= FIllegal;		(* M-: *)
  DispTab[315]	:= FIndForComm;		(* M-; *)
  DispTab[316]	:= FGoToBeg;		(* M-< *)
  DispTab[317]	:= FIllegal;		(* M-= *)
  DispTab[318]	:= FGoToEnd;		(* M-> *)
  DispTab[319]	:= FCDescribe;		(* M-? *)
  DispTab[320]	:= FMarkWord;		(* M-@ *)
  DispTab[321]	:= FBwdSentence;	(* M-A *)
  DispTab[322]	:= FBwdWord;		(* M-B *)
  DispTab[323]	:= FUpInitial;		(* M-C *)
  DispTab[324]	:= FKillWord;		(* M-D *)
  DispTab[325]	:= FFwdSentence;	(* M-E *)
  DispTab[326]	:= FFwdWord;		(* M-F *)
  DispTab[327]	:= FFillRegion;		(* M-G *)
  DispTab[328]	:= FMarkParagraph;	(* M-H *)
  DispTab[329]	:= FToTabStop;		(* M-I *)
  DispTab[330]	:= FIndNewComm;		(* M-J *)
  DispTab[331]	:= FKillSentence;	(* M-K *)
  DispTab[332]	:= FLowWord;		(* M-L *)
  DispTab[333]	:= FBackToIndent;	(* M-M *)
  DispTab[334]	:= FDownCommLine;	(* M-N *)
  DispTab[335]	:= FVT100Pad;		(* M-O *)
  DispTab[336]	:= FUpCommLine;		(* M-P *)
  DispTab[337]	:= FFillParagraph;	(* M-Q *)
  DispTab[338]	:= FMoveToEdge;		(* M-R *)
  DispTab[339]	:= FCenterLine;		(* M-S *)
  DispTab[340]	:= FTrnWords;		(* M-T *)
  DispTab[341]	:= FUpWord;		(* M-U *)
  DispTab[342]	:= FPrevScreen;		(* M-V *)
  DispTab[343]	:= FCopyRegion;		(* M-W *)
  DispTab[344]	:= FExtend;		(* M-X *)
  DispTab[345]	:= FUnKillPop;		(* M-Y *)
  DispTab[346]	:= FIllegal;		(* M-Z *)
  DispTab[347]	:= FBwdParagraph;	(* M-[ *)
  DispTab[348]	:= FDelHorSpace;	(* M-Backslash *)
  DispTab[349]	:= FFwdParagraph;	(* M-] *)
  DispTab[350]	:= FDelIndentation;	(* M-^ *)
  DispTab[351]	:= FIllegal;		(* M-_ *)
  DispTab[352]	:= FIllegal;		(* M-` *)
  DispTab[353]	:= FIllegal;		(* M-a *)
  DispTab[354]	:= FIllegal;		(* M-b *)
  DispTab[355]	:= FIllegal;		(* M-c *)
  DispTab[356]	:= FIllegal;		(* M-d *)
  DispTab[357]	:= FIllegal;		(* M-e *)
  DispTab[358]	:= FIllegal;		(* M-f *)
  DispTab[359]	:= FIllegal;		(* M-g *)
  DispTab[360]	:= FIllegal;		(* M-h *)
  DispTab[361]	:= FIllegal;		(* M-i *)
  DispTab[362]	:= FIllegal;		(* M-j *)
  DispTab[363]	:= FIllegal;		(* M-k *)
  DispTab[364]	:= FIllegal;		(* M-l *)
  DispTab[365]	:= FIllegal;		(* M-m *)
  DispTab[366]	:= FIllegal;		(* M-n *)
  DispTab[367]	:= FIllegal;		(* M-o *)
  DispTab[368]	:= FIllegal;		(* M-p *)
  DispTab[369]	:= FIllegal;		(* M-q *)
  DispTab[370]	:= FIllegal;		(* M-r *)
  DispTab[371]	:= FIllegal;		(* M-s *)
  DispTab[372]	:= FIllegal;		(* M-t *)
  DispTab[373]	:= FIllegal;		(* M-u *)
  DispTab[374]	:= FIllegal;		(* M-v *)
  DispTab[375]	:= FIllegal;		(* M-w *)
  DispTab[376]	:= FIllegal;		(* M-x *)
  DispTab[377]	:= FIllegal;		(* M-y *)
  DispTab[378]	:= FIllegal;		(* M-z *)
  DispTab[379]	:= FBwdParagraph;	(* M-{ *)
  DispTab[380]	:= FDelHorSpace;	(* M-| *)
  DispTab[381]	:= FFwdParagraph;	(* M-RightBrace *)
  DispTab[382]	:= FBufNotModified;	(* M-~ *)
  DispTab[383]	:= FBwdKilWord;		(* M-Rubout *)  (* M- *)

  DispTab[384]	:= FIllegal;		(* M- *)    (* M-8 *)
  DispTab[385]	:= FIllegal;		(* M- *)
  DispTab[386]	:= FIllegal;		(* M- *)
  DispTab[387]	:= FIllegal;		(* M- *)
  DispTab[388]	:= FIllegal;		(* M-IND *)
  DispTab[389]	:= FIllegal;		(* M-NEL *)
  DispTab[390]	:= FIllegal;		(* M-SSA *)
  DispTab[391]	:= FIllegal;		(* M-ESA *)
  DispTab[392]	:= FIllegal;		(* M-HTS *)
  DispTab[393]	:= FIllegal;		(* M-HTJ *)
  DispTab[394]	:= FIllegal;		(* M-VTS *)
  DispTab[395]	:= FIllegal;		(* M-PLD *)
  DispTab[396]	:= FIllegal;		(* M-PLU *)
  DispTab[397]	:= FIllegal;		(* M-RI *)
  DispTab[398]	:= FIllegal;		(* M-SS2 *)
  DispTab[399]	:= FIllegal;		(* M-SS3 *)
  DispTab[400]	:= FIllegal;		(* M-DCS *)
  DispTab[401]	:= FIllegal;		(* M-PU1 *)
  DispTab[402]	:= FIllegal;		(* M-PU2 *)
  DispTab[403]	:= FIllegal;		(* M-STS *)
  DispTab[404]	:= FIllegal;		(* M-CCH *)
  DispTab[405]	:= FIllegal;		(* M-MW *)
  DispTab[406]	:= FIllegal;		(* M-SPA *)
  DispTab[407]	:= FIllegal;		(* M-EPA *)
  DispTab[408]	:= FIllegal;		(* M- *)
  DispTab[409]	:= FIllegal;		(* M- *)
  DispTab[410]	:= FIllegal;		(* M- *)
  DispTab[411]	:= FIllegal;		(* M-CSI *)
  DispTab[412]	:= FIllegal;		(* M-ST *)
  DispTab[413]	:= FIllegal;		(* M-OSC *)
  DispTab[414]	:= FIllegal;		(* M-PM *)
  DispTab[415]	:= FIllegal;		(* M-APC *)
  DispTab[416]	:= FIllegal;		(* M- *)
  DispTab[417]	:= FIllegal;		(* M-Inverse ! *)
  DispTab[418]	:= FIllegal;		(* M-cent sign *)
  DispTab[419]	:= FIllegal;		(* M-pound sign *)
  DispTab[420]	:= FIllegal;		(* M- *)
  DispTab[421]	:= FIllegal;		(* M-Yen sign *)
  DispTab[422]	:= FIllegal;		(* M- *)
  DispTab[423]	:= FIllegal;		(* M-section sign *)
  DispTab[424]	:= FIllegal;		(* M- *)
  DispTab[425]	:= FIllegal;		(* M-copyright *)
  DispTab[426]	:= FIllegal;		(* M-fem. ordinal *)
  DispTab[427]	:= FIllegal;		(* M-<< *)
  DispTab[428]	:= FIllegal;		(* M- *)
  DispTab[429]	:= FIllegal;		(* M- *)
  DispTab[430]	:= FIllegal;		(* M- *)
  DispTab[431]	:= FIllegal;		(* M- *)
  DispTab[432]	:= FIllegal;		(* M-degree *)
  DispTab[433]	:= FIllegal;		(* M-+- *)
  DispTab[434]	:= FIllegal;		(* M-super 2 *)
  DispTab[435]	:= FIllegal;		(* M-super 3 *)
  DispTab[436]	:= FIllegal;		(* M- *)
  DispTab[437]	:= FIllegal;		(* M-micro *)
  DispTab[438]	:= FIllegal;		(* M-pilcrow *)
  DispTab[439]	:= FIllegal;		(* M-center dot *)
  DispTab[440]	:= FIllegal;		(* M- *)
  DispTab[441]	:= FIllegal;		(* M-super 1 *)
  DispTab[442]	:= FIllegal;		(* M-male ordinal *)
  DispTab[443]	:= FIllegal;		(* M->> *)
  DispTab[444]	:= FIllegal;		(* M-1/4 *)
  DispTab[445]	:= FIllegal;		(* M-1/2 *)
  DispTab[446]	:= FIllegal;		(* M- *)
  DispTab[447]	:= FIllegal;		(* M-inverse ? *)
  DispTab[448]	:= FIllegal;		(* M-A` *)
  DispTab[449]	:= FIllegal;		(* M-A' *)
  DispTab[450]	:= FIllegal;		(* M-A^ *)
  DispTab[451]	:= FIllegal;		(* M-A~ *)
  DispTab[452]	:= FIllegal;		(* M-A" *)
  DispTab[453]	:= FIllegal;		(* M-A* *)
  DispTab[454]	:= FIllegal;		(* M-AE *)
  DispTab[455]	:= FIllegal;		(* M-C, *)
  DispTab[456]	:= FIllegal;		(* M-E` *)
  DispTab[457]	:= FIllegal;		(* M-E' *)
  DispTab[458]	:= FIllegal;		(* M-E^ *)
  DispTab[459]	:= FIllegal;		(* M-E" *)
  DispTab[460]	:= FIllegal;		(* M-I` *)
  DispTab[461]	:= FIllegal;		(* M-I' *)
  DispTab[462]	:= FIllegal;		(* M-I^ *)
  DispTab[463]	:= FIllegal;		(* M-I" *)
  DispTab[464]	:= FIllegal;		(* M- *)
  DispTab[465]	:= FIllegal;		(* M-N~ *)
  DispTab[466]	:= FIllegal;		(* M-O` *)
  DispTab[467]	:= FIllegal;		(* M-O' *)
  DispTab[468]	:= FIllegal;		(* M-O^ *)
  DispTab[469]	:= FIllegal;		(* M-O~ *)
  DispTab[470]	:= FIllegal;		(* M-O" *)
  DispTab[471]	:= FIllegal;		(* M-OE *)
  DispTab[472]	:= FIllegal;		(* M-O/ *)
  DispTab[473]	:= FIllegal;		(* M-U` *)
  DispTab[474]	:= FIllegal;		(* M-U' *)
  DispTab[475]	:= FIllegal;		(* M-U^ *)
  DispTab[476]	:= FIllegal;		(* M-U" *)
  DispTab[477]	:= FIllegal;		(* M-Y" *)
  DispTab[478]	:= FIllegal;		(* M- *)
  DispTab[479]	:= FIllegal;		(* M-ss *)
  DispTab[480]	:= FIllegal;		(* M-a` *)
  DispTab[481]	:= FIllegal;		(* M-a' *)
  DispTab[482]	:= FIllegal;		(* M-a^ *)
  DispTab[483]	:= FIllegal;		(* M-a~ *)
  DispTab[484]	:= FIllegal;		(* M-a" *)
  DispTab[485]	:= FIllegal;		(* M-a* *)
  DispTab[486]	:= FIllegal;		(* M-ae *)
  DispTab[487]	:= FIllegal;		(* M-c, *)
  DispTab[488]	:= FIllegal;		(* M-e` *)
  DispTab[489]	:= FIllegal;		(* M-e' *)
  DispTab[490]	:= FIllegal;		(* M-e^ *)
  DispTab[491]	:= FIllegal;		(* M-e" *)
  DispTab[492]	:= FIllegal;		(* M-i` *)
  DispTab[493]	:= FIllegal;		(* M-i' *)
  DispTab[494]	:= FIllegal;		(* M-i^ *)
  DispTab[495]	:= FIllegal;		(* M-i" *)
  DispTab[496]	:= FIllegal;		(* M- *)
  DispTab[497]	:= FIllegal;		(* M-n~ *)
  DispTab[498]	:= FIllegal;		(* M-o` *)
  DispTab[499]	:= FIllegal;		(* M-o' *)
  DispTab[500]	:= FIllegal;		(* M-o^ *)
  DispTab[501]	:= FIllegal;		(* M-o~ *)
  DispTab[502]	:= FIllegal;		(* M-o" *)
  DispTab[503]	:= FIllegal;		(* M-oe *)
  DispTab[504]	:= FIllegal;		(* M-o/ *)
  DispTab[505]	:= FIllegal;		(* M-u` *)
  DispTab[506]	:= FIllegal;		(* M-u' *)
  DispTab[507]	:= FIllegal;		(* M-u^ *)
  DispTab[508]	:= FIllegal;		(* M-u" *)
  DispTab[509]	:= FIllegal;		(* M-y" *)
  DispTab[510]	:= FIllegal;		(* M- *)
  DispTab[511]	:= FIllegal;		(* M- *)     (* M-8 *)

  DispTab[512]	:= FIllegal;		(* C-^@ *)   (* C- *)
  DispTab[513]	:= FIllegal;		(* C-^A *)
  DispTab[514]	:= FIllegal;		(* C-^B *)
  DispTab[515]	:= FIllegal;		(* C-^C *)
  DispTab[516]	:= FIllegal;		(* C-^D *)
  DispTab[517]	:= FIllegal;		(* C-^E *)
  DispTab[518]	:= FIllegal;		(* C-^F *)
  DispTab[519]	:= FIllegal;		(* C-^G *)
  DispTab[520]	:= FBwdChar;		(* C-Backspace *)
  DispTab[521]	:= FToTabStop;		(* C-Tab *)
  DispTab[522]	:= FIndNewLine;		(* C-Linefeed *)
  DispTab[523]	:= FIllegal;		(* C-^K *)
  DispTab[524]	:= FIllegal;		(* C-^L *)
  DispTab[525]	:= FCrLf;		(* C-Return *)
  DispTab[526]	:= FIllegal;		(* C-^N *)
  DispTab[527]	:= FIllegal;		(* C-^O *)
  DispTab[528]	:= FIllegal;		(* C-^P *)
  DispTab[529]	:= FIllegal;		(* C-^Q *)
  DispTab[530]	:= FIllegal;		(* C-^R *)
  DispTab[531]	:= FIllegal;		(* C-^S *)
  DispTab[532]	:= FIllegal;		(* C-^T *)
  DispTab[533]	:= FIllegal;		(* C-^U *)
  DispTab[534]	:= FIllegal;		(* C-^V *)
  DispTab[535]	:= FIllegal;		(* C-^W *)
  DispTab[536]	:= FIllegal;		(* C-^X *)
  DispTab[537]	:= FIllegal;		(* C-^Y *)
  DispTab[538]	:= FIllegal;		(* C-^Z *)
  DispTab[539]	:= FExit;		(* C-Escape *)
  DispTab[540]	:= FIllegal;		(* C-^Backslash *)
  DispTab[541]	:= FIllegal;		(* C-^] *)
  DispTab[542]	:= FIllegal;		(* C-^^ *)
  DispTab[543]	:= FIllegal;		(* C-^_ *)
  DispTab[544]	:= FSetPopMark;		(* C-Space *)
  DispTab[545]	:= FIllegal;		(* C-! *)
  DispTab[546]	:= FIllegal;		(* C-" *)
  DispTab[547]	:= FIllegal;		(* C-# *)
  DispTab[548]	:= FIllegal;		(* C-$ *)
  DispTab[549]	:= FReplace;		(* C-% *)
  DispTab[550]	:= FIllegal;		(* C-& *)
  DispTab[551]	:= FIllegal;		(* C-' *)
  DispTab[552]	:= FIllegal;		(* C-( *)
  DispTab[553]	:= FIllegal;		(* C-) *)
  DispTab[554]	:= FIllegal;		(* C-* *)
  DispTab[555]	:= FIllegal;		(* C-+ *)
  DispTab[556]	:= FIllegal;		(* C-, *)
  DispTab[557]	:= FNegArgument;	(* C-- *)
  DispTab[558]	:= FIllegal;		(* C-. *)
  DispTab[559]	:= FIllegal;		(* C-/ *)
  DispTab[560]	:= FArgumentDigit;	(* C-0 *)
  DispTab[561]	:= FArgumentDigit;	(* C-1 *)
  DispTab[562]	:= FArgumentDigit;	(* C-2 *)
  DispTab[563]	:= FArgumentDigit;	(* C-3 *)
  DispTab[564]	:= FArgumentDigit;	(* C-4 *)
  DispTab[565]	:= FArgumentDigit;	(* C-5 *)
  DispTab[566]	:= FArgumentDigit;	(* C-6 *)
  DispTab[567]	:= FArgumentDigit;	(* C-7 *)
  DispTab[568]	:= FArgumentDigit;	(* C-8 *)
  DispTab[569]	:= FArgumentDigit;	(* C-9 *)
  DispTab[570]	:= FIllegal;		(* C-: *)
  DispTab[571]	:= FIndForComm;		(* C-; *)
  DispTab[572]	:= FMarkBeg;		(* C-< *)
  DispTab[573]	:= FWhatCursorPos;	(* C-= *)
  DispTab[574]	:= FMarkEnd;		(* C-> *)
  DispTab[575]	:= FDocumentation;	(* C-? *)
  DispTab[576]	:= FSetPopMark;		(* C-@ *)
  DispTab[577]	:= FBegLine;		(* C-A *)
  DispTab[578]	:= FBwdChar;		(* C-B *)
  DispTab[579]	:= FReturn;		(* C-C *)
  DispTab[580]	:= FDelChar;		(* C-D *)
  DispTab[581]	:= FEndLine;		(* C-E *)
  DispTab[582]	:= FFwdChar;		(* C-F *)
  DispTab[583]	:= FQuit;		(* C-G *)
  DispTab[584]	:= FIllegal;		(* C-H *)
  DispTab[585]	:= FIllegal;		(* C-I *)
  DispTab[586]	:= FIllegal;		(* C-J *)
  DispTab[587]	:= FKilLine;		(* C-K *)
  DispTab[588]	:= FNewWindow;		(* C-L *)
  DispTab[589]	:= FIllegal;		(* C-M *)
  DispTab[590]	:= FDownLine;		(* C-N *)
  DispTab[591]	:= FOpenLine;		(* C-O *)
  DispTab[592]	:= FUpLine;		(* C-P *)
  DispTab[593]	:= FQInsert;		(* C-Q *)
  DispTab[594]	:= FRSearch;		(* C-R *)
  DispTab[595]	:= FISearch;		(* C-S *)
  DispTab[596]	:= FTrnChar;		(* C-T *)
  DispTab[597]	:= FUnivArgument;	(* C-U *)
  DispTab[598]	:= FNextScreen;		(* C-V *)
  DispTab[599]	:= FKillRegion;		(* C-W *)
  DispTab[600]	:= FChrExtend;		(* C-X *)
  DispTab[601]	:= FUnKill;		(* C-Y *)
  DispTab[602]	:= FPfxCM;		(* C-Z *)
  DispTab[603]	:= FIllegal;		(* C-[ *)
  DispTab[604]	:= FPfxMeta;		(* C-Backslash *)
  DispTab[605]	:= FAbort;		(* C-] *)
  DispTab[606]	:= FPfxControl;		(* C-^ *)
  DispTab[607]	:= FDocumentation;	(* C-_ *)
  DispTab[608]	:= FIllegal;		(* C-` *)
  DispTab[609]	:= FIllegal;		(* C-a *)
  DispTab[610]	:= FIllegal;		(* C-b *)
  DispTab[611]	:= FIllegal;		(* C-c *)
  DispTab[612]	:= FIllegal;		(* C-d *)
  DispTab[613]	:= FIllegal;		(* C-e *)
  DispTab[614]	:= FIllegal;		(* C-f *)
  DispTab[615]	:= FIllegal;		(* C-g *)
  DispTab[616]	:= FIllegal;		(* C-h *)
  DispTab[617]	:= FIllegal;		(* C-i *)
  DispTab[618]	:= FIllegal;		(* C-j *)
  DispTab[619]	:= FIllegal;		(* C-k *)
  DispTab[620]	:= FIllegal;		(* C-l *)
  DispTab[621]	:= FIllegal;		(* C-m *)
  DispTab[622]	:= FIllegal;		(* C-n *)
  DispTab[623]	:= FIllegal;		(* C-o *)
  DispTab[624]	:= FIllegal;		(* C-p *)
  DispTab[625]	:= FIllegal;		(* C-q *)
  DispTab[626]	:= FIllegal;		(* C-r *)
  DispTab[627]	:= FIllegal;		(* C-s *)
  DispTab[628]	:= FIllegal;		(* C-t *)
  DispTab[629]	:= FIllegal;		(* C-u *)
  DispTab[630]	:= FIllegal;		(* C-v *)
  DispTab[631]	:= FIllegal;		(* C-w *)
  DispTab[632]	:= FIllegal;		(* C-x *)
  DispTab[633]	:= FIllegal;		(* C-y *)
  DispTab[634]	:= FIllegal;		(* C-z *)
  DispTab[635]	:= FIllegal;		(* C-{ *)
  DispTab[636]	:= FIllegal;		(* C-| *)
  DispTab[637]	:= FIllegal;		(* C-RightBrace *)
  DispTab[638]	:= FIllegal;		(* C-~ *)
  DispTab[639]	:= FBwdDelHackTab;	(* C-Rubout *)    (* C- *)

  DispTab[640]	:= FIllegal;		(* C- *)       (* C-8 *)
  DispTab[641]	:= FIllegal;		(* C- *)
  DispTab[642]	:= FIllegal;		(* C- *)
  DispTab[643]	:= FIllegal;		(* C- *)
  DispTab[644]	:= FIllegal;		(* C-IND *)
  DispTab[645]	:= FIllegal;		(* C-NEL *)
  DispTab[646]	:= FIllegal;		(* C-SSA *)
  DispTab[647]	:= FIllegal;		(* C-ESA *)
  DispTab[648]	:= FIllegal;		(* C-HTS *)
  DispTab[649]	:= FIllegal;		(* C-HTJ *)
  DispTab[650]	:= FIllegal;		(* C-VTS *)
  DispTab[651]	:= FIllegal;		(* C-PLD *)
  DispTab[652]	:= FIllegal;		(* C-PLU *)
  DispTab[653]	:= FIllegal;		(* C-RI *)
  DispTab[654]	:= FIllegal;		(* C-SS2 *)
  DispTab[655]	:= FIllegal;		(* C-SS3 *)
  DispTab[656]	:= FIllegal;		(* C-DCS *)
  DispTab[657]	:= FIllegal;		(* C-PU1 *)
  DispTab[658]	:= FIllegal;		(* C-PU2 *)
  DispTab[659]	:= FIllegal;		(* C-STS *)
  DispTab[660]	:= FIllegal;		(* C-CCH *)
  DispTab[661]	:= FIllegal;		(* C-MW *)
  DispTab[662]	:= FIllegal;		(* C-SPA *)
  DispTab[663]	:= FIllegal;		(* C-EPA *)
  DispTab[664]	:= FIllegal;		(* C- *)
  DispTab[665]	:= FIllegal;		(* C- *)
  DispTab[666]	:= FIllegal;		(* C- *)
  DispTab[667]	:= FIllegal;		(* C-CSI *)
  DispTab[668]	:= FIllegal;		(* C-ST *)
  DispTab[669]	:= FIllegal;		(* C-OSC *)
  DispTab[670]	:= FIllegal;		(* C-PM *)
  DispTab[671]	:= FIllegal;		(* C-APC *)
  DispTab[672]	:= FIllegal;		(* C-Invalid char *)
  DispTab[673]	:= FIllegal;		(* C-Inverse ! *)
  DispTab[674]	:= FIllegal;		(* C-cent sign *)
  DispTab[675]	:= FIllegal;		(* C-pound sign *)
  DispTab[676]	:= FIllegal;		(* C- *)
  DispTab[677]	:= FIllegal;		(* C-Yen sign *)
  DispTab[678]	:= FIllegal;		(* C- *)
  DispTab[679]	:= FIllegal;		(* C-section sign *)
  DispTab[680]	:= FIllegal;		(* C-sol *)
  DispTab[681]	:= FIllegal;		(* C-copyright *)
  DispTab[682]	:= FIllegal;		(* C-fem. ordinal *)
  DispTab[683]	:= FIllegal;		(* C-<< *)
  DispTab[684]	:= FIllegal;		(* C- *)
  DispTab[685]	:= FIllegal;		(* C- *)
  DispTab[686]	:= FIllegal;		(* C- *)
  DispTab[687]	:= FIllegal;		(* C- *)
  DispTab[688]	:= FIllegal;		(* C-degree *)
  DispTab[689]	:= FIllegal;		(* C-+- *)
  DispTab[690]	:= FIllegal;		(* C-super 2 *)
  DispTab[691]	:= FIllegal;		(* C-super 3 *)
  DispTab[692]	:= FIllegal;		(* C- *)
  DispTab[693]	:= FIllegal;		(* C-micro *)
  DispTab[694]	:= FIllegal;		(* C-pilcrow *)
  DispTab[695]	:= FIllegal;		(* C-center dot *)
  DispTab[696]	:= FIllegal;		(* C- *)
  DispTab[697]	:= FIllegal;		(* C-super 1 *)
  DispTab[698]	:= FIllegal;		(* C-male ordinal *)
  DispTab[699]	:= FIllegal;		(* C->> *)
  DispTab[700]	:= FIllegal;		(* C-1/4 *)
  DispTab[701]	:= FIllegal;		(* C-1/2 *)
  DispTab[702]	:= FIllegal;		(* C- *)
  DispTab[703]	:= FIllegal;		(* C-inverse ? *)
  DispTab[704]	:= FIllegal;		(* C-A` *)
  DispTab[705]	:= FIllegal;		(* C-A' *)
  DispTab[706]	:= FIllegal;		(* C-A^ *)
  DispTab[707]	:= FIllegal;		(* C-A~ *)
  DispTab[708]	:= FIllegal;		(* C-A" *)
  DispTab[709]	:= FIllegal;		(* C-A* *)
  DispTab[710]	:= FIllegal;		(* C-AE *)
  DispTab[711]	:= FIllegal;		(* C-C, *)
  DispTab[712]	:= FIllegal;		(* C-E` *)
  DispTab[713]	:= FIllegal;		(* C-E' *)
  DispTab[714]	:= FIllegal;		(* C-E^ *)
  DispTab[715]	:= FIllegal;		(* C-E" *)
  DispTab[716]	:= FIllegal;		(* C-I` *)
  DispTab[717]	:= FIllegal;		(* C-I' *)
  DispTab[718]	:= FIllegal;		(* C-I^ *)
  DispTab[719]	:= FIllegal;		(* C-I" *)
  DispTab[720]	:= FIllegal;		(* C- *)
  DispTab[721]	:= FIllegal;		(* C-N~ *)
  DispTab[722]	:= FIllegal;		(* C-O` *)
  DispTab[723]	:= FIllegal;		(* C-O' *)
  DispTab[724]	:= FIllegal;		(* C-O^ *)
  DispTab[725]	:= FIllegal;		(* C-O~ *)
  DispTab[726]	:= FIllegal;		(* C-O" *)
  DispTab[727]	:= FIllegal;		(* C-OE *)
  DispTab[728]	:= FIllegal;		(* C-O/ *)
  DispTab[729]	:= FIllegal;		(* C-U` *)
  DispTab[730]	:= FIllegal;		(* C-U' *)
  DispTab[731]	:= FIllegal;		(* C-U^ *)
  DispTab[732]	:= FIllegal;		(* C-U" *)
  DispTab[733]	:= FIllegal;		(* C-Y" *)
  DispTab[734]	:= FIllegal;		(* C- *)
  DispTab[735]	:= FIllegal;		(* C-ss *)
  DispTab[736]	:= FIllegal;		(* C-a` *)
  DispTab[737]	:= FIllegal;		(* C-a' *)
  DispTab[738]	:= FIllegal;		(* C-a^ *)
  DispTab[739]	:= FIllegal;		(* C-a~ *)
  DispTab[740]	:= FIllegal;		(* C-a" *)
  DispTab[741]	:= FIllegal;		(* C-a* *)
  DispTab[742]	:= FIllegal;		(* C-ae *)
  DispTab[743]	:= FIllegal;		(* C-c, *)
  DispTab[744]	:= FIllegal;		(* C-e` *)
  DispTab[745]	:= FIllegal;		(* C-e' *)
  DispTab[746]	:= FIllegal;		(* C-e^ *)
  DispTab[747]	:= FIllegal;		(* C-e" *)
  DispTab[748]	:= FIllegal;		(* C-i` *)
  DispTab[749]	:= FIllegal;		(* C-i' *)
  DispTab[750]	:= FIllegal;		(* C-i^ *)
  DispTab[751]	:= FIllegal;		(* C-i" *)
  DispTab[752]	:= FIllegal;		(* C- *)
  DispTab[753]	:= FIllegal;		(* C-n~ *)
  DispTab[754]	:= FIllegal;		(* C-o` *)
  DispTab[755]	:= FIllegal;		(* C-o' *)
  DispTab[756]	:= FIllegal;		(* C-o^ *)
  DispTab[757]	:= FIllegal;		(* C-o~ *)
  DispTab[758]	:= FIllegal;		(* C-o" *)
  DispTab[759]	:= FIllegal;		(* C-oe *)
  DispTab[760]	:= FIllegal;		(* C-o/ *)
  DispTab[761]	:= FIllegal;		(* C-u` *)
  DispTab[762]	:= FIllegal;		(* C-u' *)
  DispTab[763]	:= FIllegal;		(* C-u^ *)
  DispTab[764]	:= FIllegal;		(* C-u" *)
  DispTab[765]	:= FIllegal;		(* C-y" *)
  DispTab[766]	:= FIllegal;		(* C- *)
  DispTab[767]	:= FIllegal;		(* C- *)      (* C-8 *)

  DispTab[768]	:= FIllegal;		(* C-M-^@ *)  (* C-M- *)
  DispTab[769]	:= FIllegal;		(* C-M-^A *)
  DispTab[770]	:= FIllegal;		(* C-M-^B *)
  DispTab[771]	:= FIllegal;		(* C-M-^C *)
  DispTab[772]	:= FIllegal;		(* C-M-^D *)
  DispTab[773]	:= FIllegal;		(* C-M-^E *)
  DispTab[774]	:= FIllegal;		(* C-M-^F *)
  DispTab[775]	:= FIllegal;		(* C-M-^G *)
  DispTab[776]	:= FIllegal;		(* C-M-Backspace *)
  DispTab[777]	:= FIllegal;		(* C-M-Tab *)
  DispTab[778]	:= FIndNewComm;		(* C-M-Linefeed *)
  DispTab[779]	:= FIllegal;		(* C-M-^K *)
  DispTab[780]	:= FIllegal;		(* C-M-^L *)
  DispTab[781]	:= FBackToIndent;	(* C-M-Return *)
  DispTab[782]	:= FIllegal;		(* C-M-^N *)
  DispTab[783]	:= FIllegal;		(* C-M-^O *)
  DispTab[784]	:= FIllegal;		(* C-M-^P *)
  DispTab[785]	:= FIllegal;		(* C-M-^Q *)
  DispTab[786]	:= FIllegal;		(* C-M-^R *)
  DispTab[787]	:= FIllegal;		(* C-M-^S *)
  DispTab[788]	:= FIllegal;		(* C-M-^T *)
  DispTab[789]	:= FIllegal;		(* C-M-^U *)
  DispTab[790]	:= FIllegal;		(* C-M-^V *)
  DispTab[791]	:= FIllegal;		(* C-M-^W *)
  DispTab[792]	:= FIllegal;		(* C-M-^X *)
  DispTab[793]	:= FIllegal;		(* C-M-^Y *)
  DispTab[794]	:= FIllegal;		(* C-M-^Z *)
  DispTab[795]	:= FIllegal;		(* C-M-Escape *)
  DispTab[796]	:= FIllegal;		(* C-M-^Backslash *)
  DispTab[797]	:= FIllegal;		(* C-M-^] *)
  DispTab[798]	:= FIllegal;		(* C-M-^^ *)
  DispTab[799]	:= FIllegal;		(* C-M-^_ *)
  DispTab[800]	:= FIllegal;		(* C-M-Space *)
  DispTab[801]	:= FIllegal;		(* C-M-! *)
  DispTab[802]	:= FIllegal;		(* C-M-" *)
  DispTab[803]	:= FIllegal;		(* C-M-# *)
  DispTab[804]	:= FIllegal;		(* C-M-$ *)
  DispTab[805]	:= FIllegal;		(* C-M-% *)
  DispTab[806]	:= FIllegal;		(* C-M-& *)
  DispTab[807]	:= FIllegal;		(* C-M-' *)
  DispTab[808]	:= FIllegal;		(* C-M-( *)
  DispTab[809]	:= FIllegal;		(* C-M-) *)
  DispTab[810]	:= FIllegal;		(* C-M-* *)
  DispTab[811]	:= FIllegal;		(* C-M-+ *)
  DispTab[812]	:= FIllegal;		(* C-M-, *)
  DispTab[813]	:= FNegArgument;	(* C-M-- *)
  DispTab[814]	:= FIllegal;		(* C-M-. *)
  DispTab[815]	:= FIllegal;		(* C-M-/ *)
  DispTab[816]	:= FArgumentDigit;	(* C-M-0 *)
  DispTab[817]	:= FArgumentDigit;	(* C-M-1 *)
  DispTab[818]	:= FArgumentDigit;	(* C-M-2 *)
  DispTab[819]	:= FArgumentDigit;	(* C-M-3 *)
  DispTab[820]	:= FArgumentDigit;	(* C-M-4 *)
  DispTab[821]	:= FArgumentDigit;	(* C-M-5 *)
  DispTab[822]	:= FArgumentDigit;	(* C-M-6 *)
  DispTab[823]	:= FArgumentDigit;	(* C-M-7 *)
  DispTab[824]	:= FArgumentDigit;	(* C-M-8 *)
  DispTab[825]	:= FArgumentDigit;	(* C-M-9 *)
  DispTab[826]	:= FIllegal;		(* C-M-: *)
  DispTab[827]	:= FKillComment;	(* C-M-; *)
  DispTab[828]	:= FIllegal;		(* C-M-< *)
  DispTab[829]	:= FIllegal;		(* C-M-= *)
  DispTab[830]	:= FIllegal;		(* C-M-> *)
  DispTab[831]	:= FDocumentation;	(* C-M-? *)
  DispTab[832]	:= FIllegal;		(* C-M-@ *)
  DispTab[833]	:= FIllegal;		(* C-M-A *)
  DispTab[834]	:= FIllegal;		(* C-M-B *)
  DispTab[835]	:= FIllegal;		(* C-M-C *)
  DispTab[836]	:= FIllegal;		(* C-M-D *)
  DispTab[837]	:= FIllegal;		(* C-M-E *)
  DispTab[838]	:= FIllegal;		(* C-M-F *)
  DispTab[839]	:= FIllegal;		(* C-M-G *)
  DispTab[840]	:= FIllegal;		(* C-M-H *)
  DispTab[841]	:= FIllegal;		(* C-M-I *)
  DispTab[842]	:= FIllegal;		(* C-M-J *)
  DispTab[843]	:= FIllegal;		(* C-M-K *)
  DispTab[844]	:= FIllegal;		(* C-M-L *)
  DispTab[845]	:= FBackToIndent;	(* C-M-M *)
  DispTab[846]	:= FFwdList;		(* C-M-N *)
  DispTab[847]	:= FIllegal;		(* C-M-O *)
  DispTab[848]	:= FBwdList;		(* C-M-P *)
  DispTab[849]	:= FIndSEXP;		(* C-M-Q *)
  DispTab[850]	:= FIllegal;		(* C-M-R *)
  DispTab[851]	:= FIllegal;		(* C-M-S *)
  DispTab[852]	:= FIllegal;		(* C-M-T *)
  DispTab[853]	:= FIllegal;		(* C-M-U *)
  DispTab[854]	:= FScrollOther;	(* C-M-V *)
  DispTab[855]	:= FAppendNextKill;	(* C-M-W *)
  DispTab[856]	:= FIllegal;		(* C-M-X *)
  DispTab[857]	:= FIllegal;		(* C-M-Y *)
  DispTab[858]	:= FExit;		(* C-M-Z *)
  DispTab[859]	:= FIllegal;		(* C-M-[ *)
  DispTab[860]	:= FIndRegion;		(* C-M-Backslash *)
  DispTab[861]	:= FIllegal;		(* C-M-] *)
  DispTab[862]	:= FDelIndentation;	(* C-M-^ *)
  DispTab[863]	:= FIllegal;		(* C-M-_ *)
  DispTab[864]	:= FIllegal;		(* C-M-` *)
  DispTab[865]	:= FIllegal;		(* C-M-a *)
  DispTab[866]	:= FIllegal;		(* C-M-b *)
  DispTab[867]	:= FIllegal;		(* C-M-c *)
  DispTab[868]	:= FIllegal;		(* C-M-d *)
  DispTab[869]	:= FIllegal;		(* C-M-e *)
  DispTab[870]	:= FIllegal;		(* C-M-f *)
  DispTab[871]	:= FIllegal;		(* C-M-g *)
  DispTab[872]	:= FIllegal;		(* C-M-h *)
  DispTab[873]	:= FIllegal;		(* C-M-i *)
  DispTab[874]	:= FIllegal;		(* C-M-j *)
  DispTab[875]	:= FIllegal;		(* C-M-k *)
  DispTab[876]	:= FIllegal;		(* C-M-l *)
  DispTab[877]	:= FIllegal;		(* C-M-m *)
  DispTab[878]	:= FIllegal;		(* C-M-n *)
  DispTab[879]	:= FIllegal;		(* C-M-o *)
  DispTab[880]	:= FIllegal;		(* C-M-p *)
  DispTab[881]	:= FIllegal;		(* C-M-q *)
  DispTab[882]	:= FIllegal;		(* C-M-r *)
  DispTab[883]	:= FIllegal;		(* C-M-s *)
  DispTab[884]	:= FIllegal;		(* C-M-t *)
  DispTab[885]	:= FIllegal;		(* C-M-u *)
  DispTab[886]	:= FIllegal;		(* C-M-v *)
  DispTab[887]	:= FIllegal;		(* C-M-w *)
  DispTab[888]	:= FIllegal;		(* C-M-x *)
  DispTab[889]	:= FIllegal;		(* C-M-y *)
  DispTab[890]	:= FIllegal;		(* C-M-z *)
  DispTab[891]	:= FIllegal;		(* C-M-{ *)
  DispTab[892]	:= FIllegal;		(* C-M-| *)
  DispTab[893]	:= FIllegal;		(* C-M-RightBrace *)
  DispTab[894]	:= FIllegal;		(* C-M-~ *)
  DispTab[895]	:= FIllegal;		(* C-M-Rubout *) (* C-M- *)

  DispTab[896]	:= FIllegal;		(* C-M- *)     (* C-M-8 *)
  DispTab[897]	:= FIllegal;		(* C-M- *)
  DispTab[898]	:= FIllegal;		(* C-M- *)
  DispTab[899]	:= FIllegal;		(* C-M- *)
  DispTab[900]	:= FIllegal;		(* C-M-IND *)
  DispTab[901]	:= FIllegal;		(* C-M-NEL *)
  DispTab[902]	:= FIllegal;		(* C-M-SSA *)
  DispTab[903]	:= FIllegal;		(* C-M-ESA *)
  DispTab[904]	:= FIllegal;		(* C-M-HTS *)
  DispTab[905]	:= FIllegal;		(* C-M-HTJ *)
  DispTab[906]	:= FIllegal;		(* C-M-VTS *)
  DispTab[907]	:= FIllegal;		(* C-M-PLD *)
  DispTab[908]	:= FIllegal;		(* C-M-PLU *)
  DispTab[909]	:= FIllegal;		(* C-M-RI *)
  DispTab[910]	:= FIllegal;		(* C-M-SS2 *)
  DispTab[911]	:= FIllegal;		(* C-M-SS3 *)
  DispTab[912]	:= FIllegal;		(* C-M-DCS *)
  DispTab[913]	:= FIllegal;		(* C-M-PU1 *)
  DispTab[914]	:= FIllegal;		(* C-M-PU2 *)
  DispTab[915]	:= FIllegal;		(* C-M-STS *)
  DispTab[916]	:= FIllegal;		(* C-M-CCH *)
  DispTab[917]	:= FIllegal;		(* C-M-MW *)
  DispTab[918]	:= FIllegal;		(* C-M-SPA *)
  DispTab[919]	:= FIllegal;		(* C-M-EPA *)
  DispTab[920]	:= FIllegal;		(* C-M- *)
  DispTab[921]	:= FIllegal;		(* C-M- *)
  DispTab[922]	:= FIllegal;		(* C-M- *)
  DispTab[923]	:= FIllegal;		(* C-M-CSI *)
  DispTab[924]	:= FIllegal;		(* C-M-ST *)
  DispTab[925]	:= FIllegal;		(* C-M-OSC *)
  DispTab[926]	:= FIllegal;		(* C-M-PM *)
  DispTab[927]	:= FIllegal;		(* C-M-APC *)
  DispTab[928]	:= FIllegal;		(* C-M-Invalid char *)
  DispTab[929]	:= FIllegal;		(* C-M-Inverse ! *)
  DispTab[930]	:= FIllegal;		(* C-M-cent sign *)
  DispTab[931]	:= FIllegal;		(* C-M-pound sign *)
  DispTab[932]	:= FIllegal;		(* C-M- *)
  DispTab[933]	:= FIllegal;		(* C-M-Yen sign *)
  DispTab[934]	:= FIllegal;		(* C-M- *)
  DispTab[935]	:= FIllegal;		(* C-M-section sign *)
  DispTab[936]	:= FIllegal;		(* C-M-sol *)
  DispTab[937]	:= FIllegal;		(* C-M-copyright *)
  DispTab[938]	:= FIllegal;		(* C-M-fem. ordinal *)
  DispTab[939]	:= FIllegal;		(* C-M-<< *)
  DispTab[940]	:= FIllegal;		(* C-M- *)
  DispTab[941]	:= FIllegal;		(* C-M- *)
  DispTab[942]	:= FIllegal;		(* C-M- *)
  DispTab[943]	:= FIllegal;		(* C-M- *)
  DispTab[944]	:= FIllegal;		(* C-M-degree *)
  DispTab[945]	:= FIllegal;		(* C-M-+- *)
  DispTab[946]	:= FIllegal;		(* C-M-super 2 *)
  DispTab[947]	:= FIllegal;		(* C-M-super 3 *)
  DispTab[948]	:= FIllegal;		(* C-M- *)
  DispTab[949]	:= FIllegal;		(* C-M-micro *)
  DispTab[950]	:= FIllegal;		(* C-M-pilcrow *)
  DispTab[951]	:= FIllegal;		(* C-M-center dot *)
  DispTab[952]	:= FIllegal;		(* C-M- *)
  DispTab[953]	:= FIllegal;		(* C-M-super 1 *)
  DispTab[954]	:= FIllegal;		(* C-M-male ordinal *)
  DispTab[955]	:= FIllegal;		(* C-M->> *)
  DispTab[956]	:= FIllegal;		(* C-M-1/4 *)
  DispTab[957]	:= FIllegal;		(* C-M-1/2 *)
  DispTab[958]	:= FIllegal;		(* C-M- *)
  DispTab[959]	:= FIllegal;		(* C-M-inverse ? *)
  DispTab[960]	:= FIllegal;		(* C-M-A` *)
  DispTab[961]	:= FIllegal;		(* C-M-A' *)
  DispTab[962]	:= FIllegal;		(* C-M-A^ *)
  DispTab[963]	:= FIllegal;		(* C-M-A~ *)
  DispTab[964]	:= FIllegal;		(* C-M-A"  *)
  DispTab[965]	:= FIllegal;		(* C-M-A* *)
  DispTab[966]	:= FIllegal;		(* C-M-AE *)
  DispTab[967]	:= FIllegal;		(* C-M-C, *)
  DispTab[968]	:= FIllegal;		(* C-M-E` *)
  DispTab[969]	:= FIllegal;		(* C-M-E' *)
  DispTab[970]	:= FIllegal;		(* C-M-E^ *)
  DispTab[971]	:= FIllegal;		(* C-M-E" *)
  DispTab[972]	:= FIllegal;		(* C-M-I` *)
  DispTab[973]	:= FIllegal;		(* C-M-I' *)
  DispTab[974]	:= FIllegal;		(* C-M-I^ *)
  DispTab[975]	:= FIllegal;		(* C-M-I" *)
  DispTab[976]	:= FIllegal;		(* C-M- *)
  DispTab[977]	:= FIllegal;		(* C-M-N~ *)
  DispTab[978]	:= FIllegal;		(* C-M-O` *)
  DispTab[979]	:= FIllegal;		(* C-M-O' *)
  DispTab[980]	:= FIllegal;		(* C-M-O^ *)
  DispTab[981]	:= FIllegal;		(* C-M-O~ *)
  DispTab[982]	:= FIllegal;		(* C-M-O" *)
  DispTab[983]	:= FIllegal;		(* C-M-OE *)
  DispTab[984]	:= FIllegal;		(* C-M-O/ *)
  DispTab[985]	:= FIllegal;		(* C-M-U` *)
  DispTab[986]	:= FIllegal;		(* C-M-U' *)
  DispTab[987]	:= FIllegal;		(* C-M-U^ *)
  DispTab[988]	:= FIllegal;		(* C-M-U" *)
  DispTab[989]	:= FIllegal;		(* C-M-Y" *)
  DispTab[990]	:= FIllegal;		(* C-M- *)
  DispTab[991]	:= FIllegal;		(* C-M-ss *)
  DispTab[992]	:= FIllegal;		(* C-M-a` *)
  DispTab[993]	:= FIllegal;		(* C-M-a' *)
  DispTab[994]	:= FIllegal;		(* C-M-a^ *)
  DispTab[995]	:= FIllegal;		(* C-M-a~ *)
  DispTab[996]	:= FIllegal;		(* C-M-a"  *)
  DispTab[997]	:= FIllegal;		(* C-M-a* *)
  DispTab[998]	:= FIllegal;		(* C-M-ae *)
  DispTab[999]	:= FIllegal;		(* C-M-c, *)
  DispTab[1000]	:= FIllegal;		(* C-M-e` *)
  DispTab[1001]	:= FIllegal;		(* C-M-e' *)
  DispTab[1002]	:= FIllegal;		(* C-M-e^ *)
  DispTab[1003]	:= FIllegal;		(* C-M-e" *)
  DispTab[1004]	:= FIllegal;		(* C-M-i` *)
  DispTab[1005]	:= FIllegal;		(* C-M-i' *)
  DispTab[1006]	:= FIllegal;		(* C-M-i^ *)
  DispTab[1007]	:= FIllegal;		(* C-M-i" *)
  DispTab[1008]	:= FIllegal;		(* C-M- *)
  DispTab[1009]	:= FIllegal;		(* C-M-n~ *)
  DispTab[1010]	:= FIllegal;		(* C-M-o` *)
  DispTab[1011]	:= FIllegal;		(* C-M-o' *)
  DispTab[1012]	:= FIllegal;		(* C-M-o^ *)
  DispTab[1013]	:= FIllegal;		(* C-M-o~ *)
  DispTab[1014]	:= FIllegal;		(* C-M-o" *)
  DispTab[1015]	:= FIllegal;		(* C-M-oe *)
  DispTab[1016]	:= FIllegal;		(* C-M-o/ *)
  DispTab[1017]	:= FIllegal;		(* C-M-u` *)
  DispTab[1018]	:= FIllegal;		(* C-M-u' *)
  DispTab[1019]	:= FIllegal;		(* C-M-u^ *)
  DispTab[1020]	:= FIllegal;		(* C-M-u" *)
  DispTab[1021]	:= FIllegal;		(* C-M-y" *)
  DispTab[1022]	:= FIllegal;		(* C-M- *)
  DispTab[1023]	:= FIllegal;		(* C-M- *)	(* C-M-8 *)

(* ^X dispatch table *)

  CXTable[0]	:= FIllegal;		(* ^@ *)
  CXTable[1]	:= FIllegal;		(* ^A *)
  CXTable[2]	:= FListBuffers;	(* ^B *)
  CXTable[3]	:= FIllegal;		(* ^C *)
  CXTable[4]	:= FIllegal;		(* ^D *)
  CXTable[5]	:= FVisitFile;		(* ^E *)
  CXTable[6]	:= FFindFile;		(* ^F *)
  CXTable[7]	:= FIllegal;		(* ^G *)
  CXTable[8]	:= FIllegal;		(* Backspace *)
  CXTable[9]	:= FIndRigidly;		(* Tab *)
  CXTable[10]	:= FIllegal;		(* Linefeed *)
  CXTable[11]	:= FIllegal;		(* ^K *)
  CXTable[12]	:= FLowCaseReg;		(* ^L *)
  CXTable[13]	:= FIllegal;		(* Return *)
  CXTable[14]	:= FIllegal;		(* ^N *)
  CXTable[15]	:= FDelBlankLines;	(* ^O *)
  CXTable[16]	:= FMarkPage;		(* ^P *)
  CXTable[17]	:= FIllegal;		(* ^Q *)
  CXTable[18]	:= FReadFile;		(* ^R *)
  CXTable[19]	:= FSaveFile;		(* ^S *)
  CXTable[20]	:= FTrnLines;		(* ^T *)
  CXTable[21]	:= FUpCaseReg;		(* ^U *)
  CXTable[22]	:= FVisitFile;		(* ^V *)
  CXTable[23]	:= FWriteFile;		(* ^W *)
  CXTable[24]	:= FExchange;		(* ^X *)
  CXTable[25]	:= FIllegal;		(* ^Y *)
  CXTable[26]	:= FReturn;		(* ^Z *)
  CXTable[27]	:= FIllegal;		(* Escape *)
  CXTable[28]	:= FIllegal;		(* ^Backslash *)
  CXTable[29]	:= FIllegal;		(* ^] *)
  CXTable[30]	:= FIllegal;		(* ^^ *)
  CXTable[31]	:= FIllegal;		(* ^_ *)
  CXTable[32]	:= FIllegal;		(* Space *)
  CXTable[33]	:= FIllegal;		(* ! *)
  CXTable[34]	:= FIllegal;		(* " *)
  CXTable[35]	:= FIllegal;		(* # *)
  CXTable[36]	:= FIllegal;		(* $ *)
  CXTable[37]	:= FIllegal;		(* % *)
  CXTable[38]	:= FIllegal;		(* & *)
  CXTable[39]	:= FIllegal;		(* ' *)
  CXTable[40]	:= FKbdStart;		(* ( *)
  CXTable[41]	:= FKbdEnd;		(* ) *)
  CXTable[42]	:= FIllegal;		(* * *)
  CXTable[43]	:= FIllegal;		(* + *)
  CXTable[44]	:= FIllegal;		(* , *)
  CXTable[45]	:= FIllegal;		(* - *)
  CXTable[46]	:= FSetPrefixFill;	(* . *)
  CXTable[47]	:= FIllegal;		(* / *)
  CXTable[48]	:= FIllegal;		(* 0 *)
  CXTable[49]	:= F1Window;		(* 1 *)
  CXTable[50]	:= F2Windows;		(* 2 *)
  CXTable[51]	:= FIllegal;		(* 3 *)
  CXTable[52]	:= FVisitInOther;	(* 4 *)
  CXTable[53]	:= FIllegal;		(* 5 *)
  CXTable[54]	:= FIllegal;		(* 6 *)
  CXTable[55]	:= FIllegal;		(* 7 *)
  CXTable[56]	:= FIllegal;		(* 8 *)
  CXTable[57]	:= FIllegal;		(* 9 *)
  CXTable[58]	:= FIllegal;		(* : *)
  CXTable[59]	:= FSetCommColumn;	(* ; *)
  CXTable[60]	:= FIllegal;		(* < *)
  CXTable[61]	:= FWhatCursorPos;	(* = *)
  CXTable[62]	:= FIllegal;		(* > *)
  CXTable[63]	:= FIllegal;		(* ? *)
  CXTable[64]	:= FIllegal;		(* @ *)
  CXTable[65]	:= FIllegal;		(* A *)
  CXTable[66]	:= FSelectBuffer;	(* B *)
  CXTable[67]	:= FIllegal;		(* C *)
  CXTable[68]	:= FIllegal;		(* D *)
  CXTable[69]	:= FKbdExecute;		(* E *)
  CXTable[70]	:= FSetFillColumn;	(* F *)
  CXTable[71]	:= FGetQRegister;	(* G *)
  CXTable[72]	:= FMarkWhole;		(* H *)
  CXTable[73]	:= FIllegal;		(* I *)
  CXTable[74]	:= FIllegal;		(* J *)
  CXTable[75]	:= FKillBuffer;		(* K *)
  CXTable[76]	:= FCountLinesPage;	(* L *)
  CXTable[77]	:= FIllegal;		(* M *)
  CXTable[78]	:= FIllegal;		(* N *)
  CXTable[79]	:= FOtherWindow;	(* O *)
  CXTable[80]	:= FIllegal;		(* P *)
  CXTable[81]	:= FKbdQuery;		(* Q *)
  CXTable[82]	:= FIllegal;		(* R *)
  CXTable[83]	:= FIllegal;		(* S *)
  CXTable[84]	:= FTrnRegions;		(* T *)
  CXTable[85]	:= FIllegal;		(* U *)
  CXTable[86]	:= FIllegal;		(* V *)
  CXTable[87]	:= FIllegal;		(* W *)
  CXTable[88]	:= FPutQRegister;	(* X *)
  CXTable[89]	:= FIllegal;		(* Y *)
  CXTable[90]	:= FIllegal;		(* Z *)
  CXTable[91]	:= FPrevPage;		(* [ *)
  CXTable[92]	:= FIllegal;		(* Backslash *)
  CXTable[93]	:= FNextPage;		(* ] *)
  CXTable[94]	:= FGrowWindow;		(* ^ *)
  CXTable[95]	:= FIllegal;		(* _ *)
  CXTable[96]	:= FIllegal;		(* ` *)
  CXTable[97]	:= FIllegal;		(* a *)
  CXTable[98]	:= FIllegal;		(* b *)
  CXTable[99]	:= FIllegal;		(* c *)
  CXTable[100]	:= FIllegal;		(* d *)
  CXTable[101]	:= FIllegal;		(* e *)
  CXTable[102]	:= FIllegal;		(* f *)
  CXTable[103]	:= FIllegal;		(* g *)
  CXTable[104]	:= FIllegal;		(* h *)
  CXTable[105]	:= FIllegal;		(* i *)
  CXTable[106]	:= FIllegal;		(* j *)
  CXTable[107]	:= FIllegal;		(* k *)
  CXTable[108]	:= FIllegal;		(* l *)
  CXTable[109]	:= FIllegal;		(* m *)
  CXTable[110]	:= FIllegal;		(* n *)
  CXTable[111]	:= FIllegal;		(* o *)
  CXTable[112]	:= FIllegal;		(* p *)
  CXTable[113]	:= FIllegal;		(* q *)
  CXTable[114]	:= FIllegal;		(* r *)
  CXTable[115]	:= FIllegal;		(* s *)
  CXTable[116]	:= FIllegal;		(* t *)
  CXTable[117]	:= FIllegal;		(* u *)
  CXTable[118]	:= FIllegal;		(* v *)
  CXTable[119]	:= FIllegal;		(* w *)
  CXTable[120]	:= FIllegal;		(* x *)
  CXTable[121]	:= FIllegal;		(* y *)
  CXTable[122]	:= FIllegal;		(* z *)
  CXTable[123]	:= FPrevPage;		(* { *)
  CXTable[124]	:= FIllegal;		(* | *)
  CXTable[125]	:= FNextPage;		(* RightBrace *)
  CXTable[126]	:= FIllegal;		(* ~ *)
  CXTable[127]	:= FBwdKilSentence;	(* Rubout *)

  CXTable[128]	:= FIllegal;		(*     *)	(* 8 *)
  CXTable[129]	:= FIllegal;		(*     *)
  CXTable[130]	:= FIllegal;		(*     *)
  CXTable[131]	:= FIllegal;		(*     *)
  CXTable[132]	:= FIllegal;		(* IND *)
  CXTable[133]	:= FIllegal;		(* NEL *)
  CXTable[134]	:= FIllegal;		(* SSA *)
  CXTable[135]	:= FIllegal;		(* ESA *)
  CXTable[136]	:= FIllegal;		(* HTS *)
  CXTable[137]	:= FIllegal;		(* HTJ *)
  CXTable[138]	:= FIllegal;		(* VTS *)
  CXTable[139]	:= FIllegal;		(* PLD *)
  CXTable[140]	:= FIllegal;		(* PLU *)
  CXTable[141]	:= FIllegal;		(* RI  *)
  CXTable[142]	:= FIllegal;		(* SS2 *)
  CXTable[143]	:= FIllegal;		(* SS3 *)
  CXTable[144]	:= FIllegal;		(* DCS *)
  CXTable[145]	:= FIllegal;		(* PU1 *)
  CXTable[146]	:= FIllegal;		(* PU2 *)
  CXTable[147]	:= FIllegal;		(* STS *)
  CXTable[148]	:= FIllegal;		(* CCH *)
  CXTable[149]	:= FIllegal;		(* MW  *)
  CXTable[150]	:= FIllegal;		(* SPA *)
  CXTable[151]	:= FIllegal;		(* EPA *)
  CXTable[152]	:= FIllegal;		(*     *)
  CXTable[153]	:= FIllegal;		(*     *)
  CXTable[154]	:= FIllegal;		(*     *)
  CXTable[155]	:= FIllegal;		(* CSI *)
  CXTable[156]	:= FIllegal;		(* ST  *)
  CXTable[157]	:= FIllegal;		(* OSC *)
  CXTable[158]	:= FIllegal;		(* PM  *)
  CXTable[159]	:= FIllegal;		(* APC *)
  CXTable[160]	:= FIllegal;		(* Invalid char *)
  CXTable[161]	:= FIllegal;		(* Inverse ! *)
  CXTable[162]	:= FIllegal;		(* cent sign *)
  CXTable[163]	:= FIllegal;		(* pound sign *)
  CXTable[164]	:= FIllegal;		(*    *)
  CXTable[165]	:= FIllegal;		(* Yen sign *)
  CXTable[166]	:= FIllegal;		(*    *)
  CXTable[167]	:= FIllegal;		(* section sign *)
  CXTable[168]	:= FIllegal;		(* sol *)
  CXTable[169]	:= FIllegal;		(* copyright *)
  CXTable[170]	:= FIllegal;		(* fem. ordinal *)
  CXTable[171]	:= FIllegal;		(* << *)
  CXTable[172]	:= FIllegal;		(*    *)
  CXTable[173]	:= FIllegal;		(*    *)
  CXTable[174]	:= FIllegal;		(*    *)
  CXTable[175]	:= FIllegal;		(*    *)
  CXTable[176]	:= FIllegal;		(* degree *)
  CXTable[177]	:= FIllegal;		(* +- *)
  CXTable[178]	:= FIllegal;		(* super 2 *)
  CXTable[179]	:= FIllegal;		(* super 3 *)
  CXTable[180]	:= FIllegal;		(*    *)
  CXTable[181]	:= FIllegal;		(* micro *)
  CXTable[182]	:= FIllegal;		(* pilcrow *)
  CXTable[183]	:= FIllegal;		(* center dot *)
  CXTable[184]	:= FIllegal;		(*    *)
  CXTable[185]	:= FIllegal;		(* super 1 *)
  CXTable[186]	:= FIllegal;		(* male ordinal *)
  CXTable[187]	:= FIllegal;		(* >> *)
  CXTable[188]	:= FIllegal;		(* 1/4 *)
  CXTable[189]	:= FIllegal;		(* 1/2 *)
  CXTable[190]	:= FIllegal;		(*    *)
  CXTable[191]	:= FIllegal;		(* inverse ? *)
  CXTable[192]	:= FIllegal;		(* A` *)
  CXTable[193]	:= FIllegal;		(* A' *)
  CXTable[194]	:= FIllegal;		(* A^ *)
  CXTable[195]	:= FIllegal;		(* A~ *)
  CXTable[196]	:= FIllegal;		(* A" *)
  CXTable[197]	:= FIllegal;		(* A* *)
  CXTable[198]	:= FIllegal;		(* AE *)
  CXTable[199]	:= FIllegal;		(* C* *)
  CXTable[200]	:= FIllegal;		(* E` *)
  CXTable[201]	:= FIllegal;		(* E' *)
  CXTable[202]	:= FIllegal;		(* E^ *)
  CXTable[203]	:= FIllegal;		(* E" *)
  CXTable[204]	:= FIllegal;		(* I` *)
  CXTable[205]	:= FIllegal;		(* I' *)
  CXTable[206]	:= FIllegal;		(* I^ *)
  CXTable[207]	:= FIllegal;		(* I" *)
  CXTable[208]	:= FIllegal;		(*    *)
  CXTable[209]	:= FIllegal;		(* N~ *)
  CXTable[210]	:= FIllegal;		(* O` *)
  CXTable[211]	:= FIllegal;		(* O' *)
  CXTable[212]	:= FIllegal;		(* O^ *)
  CXTable[213]	:= FIllegal;		(* O~ *)
  CXTable[214]	:= FIllegal;		(* O" *)
  CXTable[215]	:= FIllegal;		(* OE *)
  CXTable[216]	:= FIllegal;		(* O/ *)
  CXTable[217]	:= FIllegal;		(* U` *)
  CXTable[218]	:= FIllegal;		(* U' *)
  CXTable[219]	:= FIllegal;		(* U^ *)
  CXTable[220]	:= FIllegal;		(* U" *)
  CXTable[221]	:= FIllegal;		(* Y" *)
  CXTable[222]	:= FIllegal;		(*    *)
  CXTable[223]	:= FIllegal;		(* ss *)
  CXTable[224]	:= FIllegal;		(* a` *)
  CXTable[225]	:= FIllegal;		(* a' *)
  CXTable[226]	:= FIllegal;		(* a^ *)
  CXTable[227]	:= FIllegal;		(* a~ *)
  CXTable[228]	:= FIllegal;		(* a" *)
  CXTable[229]	:= FIllegal;		(* a* *)
  CXTable[230]	:= FIllegal;		(* ae *)
  CXTable[231]	:= FIllegal;		(* c* *)
  CXTable[232]	:= FIllegal;		(* e` *)
  CXTable[233]	:= FIllegal;		(* e' *)
  CXTable[234]	:= FIllegal;		(* e^ *)
  CXTable[235]	:= FIllegal;		(* e" *)
  CXTable[236]	:= FIllegal;		(* i` *)
  CXTable[237]	:= FIllegal;		(* i' *)
  CXTable[238]	:= FIllegal;		(* i^ *)
  CXTable[239]	:= FIllegal;		(* i" *)
  CXTable[240]	:= FIllegal;		(*    *)
  CXTable[241]	:= FIllegal;		(* n~ *)
  CXTable[242]	:= FIllegal;		(* o` *)
  CXTable[243]	:= FIllegal;		(* o' *)
  CXTable[244]	:= FIllegal;		(* o^ *)
  CXTable[245]	:= FIllegal;		(* o~ *)
  CXTable[246]	:= FIllegal;		(* o" *)
  CXTable[247]	:= FIllegal;		(* oe *)
  CXTable[248]	:= FIllegal;		(* o/ *)
  CXTable[249]	:= FIllegal;		(* u` *)
  CXTable[250]	:= FIllegal;		(* u' *)
  CXTable[251]	:= FIllegal;		(* u^ *)
  CXTable[252]	:= FIllegal;		(* u" *)
  CXTable[253]	:= FIllegal;		(* y" *)
  CXTable[254]	:= FIllegal;		(*    *)
  CXTable[255]	:= FIllegal;		(* invalid char *)	(* 8 *)

(* VT100 keypad function table. *)

  VTTable[0]	:= FIllegal;		(* ^@ *)
  VTTable[1]	:= FIllegal;		(* ^A *)
  VTTable[2]	:= FIllegal;		(* ^B *)
  VTTable[3]	:= FIllegal;		(* ^C *)
  VTTable[4]	:= FIllegal;		(* ^D *)
  VTTable[5]	:= FIllegal;		(* ^E *)
  VTTable[6]	:= FIllegal;		(* ^F *)
  VTTable[7]	:= FIllegal;		(* ^G *)
  VTTable[8]	:= FIllegal;		(* Backspace *)
  VTTable[9]	:= FIllegal;		(* Tab *)
  VTTable[10]	:= FIllegal;		(* Linefeed *)
  VTTable[11]	:= FIllegal;		(* ^K *)
  VTTable[12]	:= FIllegal;		(* ^L *)
  VTTable[13]	:= FIllegal;		(* Return *)
  VTTable[14]	:= FIllegal;		(* ^N *)
  VTTable[15]	:= FIllegal;		(* ^O *)
  VTTable[16]	:= FIllegal;		(* ^P *)
  VTTable[17]	:= FIllegal;		(* ^Q *)
  VTTable[18]	:= FIllegal;		(* ^R *)
  VTTable[19]	:= FIllegal;		(* ^S *)
  VTTable[20]	:= FIllegal;		(* ^T *)
  VTTable[21]	:= FIllegal;		(* ^U *)
  VTTable[22]	:= FIllegal;		(* ^V *)
  VTTable[23]	:= FIllegal;		(* ^W *)
  VTTable[24]	:= FIllegal;		(* ^X *)
  VTTable[25]	:= FIllegal;		(* ^Y *)
  VTTable[26]	:= FIllegal;		(* ^Z *)
  VTTable[27]	:= FIllegal;		(* Escape *)
  VTTable[28]	:= FIllegal;		(* ^Backslash *)
  VTTable[29]	:= FIllegal;		(* ^] *)
  VTTable[30]	:= FIllegal;		(* ^^ *)
  VTTable[31]	:= FIllegal;		(* ^_ *)
  VTTable[32]	:= FIllegal;		(* Space *)
  VTTable[33]	:= FIllegal;		(* ! *)
  VTTable[34]	:= FIllegal;		(* " *)
  VTTable[35]	:= FIllegal;		(* # *)
  VTTable[36]	:= FIllegal;		(* $ *)
  VTTable[37]	:= FIllegal;		(* % *)
  VTTable[38]	:= FIllegal;		(* & *)
  VTTable[39]	:= FIllegal;		(* ' *)
  VTTable[40]	:= FIllegal;		(* ( *)
  VTTable[41]	:= FIllegal;		(* ) *)
  VTTable[42]	:= FIllegal;		(* * *)
  VTTable[43]	:= FIllegal;		(* + *)
  VTTable[44]	:= FIllegal;		(* , *)
  VTTable[45]	:= FIllegal;		(* - *)
  VTTable[46]	:= FIllegal;		(* . *)
  VTTable[47]	:= FIllegal;		(* / *)
  VTTable[48]	:= FIllegal;		(* 0 *)
  VTTable[49]	:= FIllegal;		(* 1 *)
  VTTable[50]	:= FIllegal;		(* 2 *)
  VTTable[51]	:= FIllegal;		(* 3 *)
  VTTable[52]	:= FIllegal;		(* 4 *)
  VTTable[53]	:= FIllegal;		(* 5 *)
  VTTable[54]	:= FIllegal;		(* 6 *)
  VTTable[55]	:= FIllegal;		(* 7 *)
  VTTable[56]	:= FIllegal;		(* 8 *)
  VTTable[57]	:= FIllegal;		(* 9 *)
  VTTable[58]	:= FIllegal;		(* : *)
  VTTable[59]	:= FIllegal;		(* ; *)
  VTTable[60]	:= FIllegal;		(* < *)
  VTTable[61]	:= FIllegal;		(* = *)
  VTTable[62]	:= FIllegal;		(* > *)
  VTTable[63]	:= FIllegal;		(* ? *)
  VTTable[64]	:= FIllegal;		(* @ *)
  VTTable[65]	:= FUpLine;		(* A *)
  VTTable[66]	:= FDownLine;		(* B *)
  VTTable[67]	:= FFwdChar;		(* C *)
  VTTable[68]	:= FBwdChar;		(* D *)
  VTTable[69]	:= FIllegal;		(* E *)
  VTTable[70]	:= FIllegal;		(* F *)
  VTTable[71]	:= FIllegal;		(* G *)
  VTTable[72]	:= FIllegal;		(* H *)
  VTTable[73]	:= FIllegal;		(* I *)
  VTTable[74]	:= FIllegal;		(* J *)
  VTTable[75]	:= FIllegal;		(* K *)
  VTTable[76]	:= FIllegal;		(* L *)
  VTTable[77]	:= FUnUsed;		(* M *) (* ENTER key *)
  VTTable[78]	:= FIllegal;		(* N *)
  VTTable[79]	:= FIllegal;		(* O *)
  VTTable[80]	:= FUnUsed;		(* P *) (* PF1 *)
  VTTable[81]	:= FUnUsed;		(* Q *) (* PF2 *)
  VTTable[82]	:= FUnUsed;		(* R *) (* PF3 *)
  VTTable[83]	:= FUnUsed;		(* S *) (* PF4 *)
  VTTable[84]	:= FIllegal;		(* T *)
  VTTable[85]	:= FIllegal;		(* U *)
  VTTable[86]	:= FIllegal;		(* V *)
  VTTable[87]	:= FIllegal;		(* W *)
  VTTable[88]	:= FIllegal;		(* X *)
  VTTable[89]	:= FIllegal;		(* Y *)
  VTTable[90]	:= FIllegal;		(* Z *)
  VTTable[91]	:= FIllegal;		(* [ *)
  VTTable[92]	:= FIllegal;		(* Backslash *)
  VTTable[93]	:= FIllegal;		(* ] *)
  VTTable[94]	:= FIllegal;		(* ^ *)
  VTTable[95]	:= FIllegal;		(* _ *)
  VTTable[96]	:= FIllegal;		(* ` *)
  VTTable[97]	:= FIllegal;		(* a *)
  VTTable[98]	:= FIllegal;		(* b *)
  VTTable[99]	:= FIllegal;		(* c *)
  VTTable[100]	:= FIllegal;		(* d *)
  VTTable[101]	:= FIllegal;		(* e *)
  VTTable[102]	:= FIllegal;		(* f *)
  VTTable[103]	:= FIllegal;		(* g *)
  VTTable[104]	:= FIllegal;		(* h *)
  VTTable[105]	:= FIllegal;		(* i *)
  VTTable[106]	:= FIllegal;		(* j *)
  VTTable[107]	:= FIllegal;		(* k *)
  VTTable[108]	:= FUnUsed;		(* l *) (* , *)
  VTTable[109]	:= FNegArgument;	(* m *) (* - *)
  VTTable[110]	:= FDocumentation;	(* n *) (* . *)
  VTTable[111]	:= FIllegal;		(* o *)
  VTTable[112]	:= FArgumentDigit;	(* p *) (* Digit *)
  VTTable[113]	:= FArgumentDigit;	(* q *) (* Digit *)
  VTTable[114]	:= FArgumentDigit;	(* r *) (* Digit *)
  VTTable[115]	:= FArgumentDigit;	(* s *) (* Digit *)
  VTTable[116]	:= FArgumentDigit;	(* t *) (* Digit *)
  VTTable[117]	:= FArgumentDigit;	(* u *) (* Digit *)
  VTTable[118]	:= FArgumentDigit;	(* v *) (* Digit *)
  VTTable[119]	:= FArgumentDigit;	(* w *) (* Digit *)
  VTTable[120]	:= FArgumentDigit;	(* x *) (* Digit *)
  VTTable[121]	:= FArgumentDigit;	(* y *) (* Digit *)
  VTTable[122]	:= FIllegal;		(* z *)
  VTTable[123]	:= FIllegal;		(* { *)
  VTTable[124]	:= FIllegal;		(* | *)
  VTTable[125]	:= FIllegal;		(* RightBrace *)
  VTTable[126]	:= FIllegal;		(* ~ *)
  VTTable[127]	:= FIllegal;		(* Rubout *)

  TildeTable[0]  := FIllegal;		(*  *)
  TildeTable[1]  := FISearch;		(* E1=search *)
  TildeTable[2]  := FUnKill;		(* E2=Insert *)
  TildeTable[3]  := FKillRegion;	(* E3=Delete *)
  TildeTable[4]  := FSetPopMark;	(* E4=Select *)
  TildeTable[5]  := FPrevScreen;	(* E5=Prev screen *)
  TildeTable[6]  := FNextScreen;	(* E6=Next screen *)
  TildeTable[7]  := FIllegal;		(*  *)
  TildeTable[8]  := FIllegal;		(*  *)
  TildeTable[9]  := FIllegal;		(*  *)
  TildeTable[10] := FIllegal;		(*  *)
  TildeTable[11] := FIllegal;		(*  *)
  TildeTable[12] := FIllegal;		(*  *)
  TildeTable[13] := FIllegal;		(*  *)
  TildeTable[14] := FIllegal;		(*  *)
  TildeTable[15] := FIllegal;		(*  *)
  TildeTable[16] := FIllegal;		(*  *)
  TildeTable[17] := FQuit;		(* F6=(Cancel) *)
  TildeTable[18] := FIllegal;		(* F7 *)
  TildeTable[19] := FIllegal;		(* F8 *)
  TildeTable[20] := FIllegal;		(* F9 *)
  TildeTable[21] := FExit;		(* F10=(Exit) *)
  TildeTable[22] := FIllegal;		(*  *)
  TildeTable[23] := FPfxMeta;		(* F11 *)
  TildeTable[24] := FBegLine;		(* F12=(Bol) *)
  TildeTable[25] := FBwdKilWord;	(* F13=(Del Word) *)
  TildeTable[26] := FOverWrite;		(* F14=(Ins/Ovs) *)
  TildeTable[27] := FIllegal;		(*  *)
  TildeTable[28] := FDocumentation;	(* F15=HELP *)
  TildeTable[29] := FExtend;		(* F16=DO *)
  TildeTable[30] := FIllegal;		(*  *)
  TildeTable[31] := FIllegal;		(* F17 *)
  TildeTable[32] := FIllegal;		(* F18 *)
  TildeTable[33] := FIllegal;		(* F19 *)
  TildeTable[34] := FIllegal;		(* F20 *)
  TildeTable[35] := FIllegal;		(*  *)

  MajorName [FunMode] :=	'Fundamental                             ';
  MajorName [TextMode] :=       'Text                                    ';
  MajorName [AlgolMode] :=      'Algol                                   ';
  MajorName [MacroMode] :=      'Macro                                   ';
  MajorName [PascalMode] :=     'Pascal                                  ';
  MajorName [LispMode] :=       'LISP                                    ';
  MajorName [CMode] :=		'C                                       ';
  MajorName [TeXMode] :=	'TeX                                     ';
  MajorName [AdaMode] :=	'ADA                                     ';
  MajorName [ModulaMode] :=	'Modula-2                                ';
  MajorName [PL1Mode] :=	'PL/1                                    ';
  MajorName [BlissMode] :=	'BLISS                                   ';

  MinorName [FillMode] :=       'Fill                                    ';
  MinorName [SwedMode] :=       'Swedish                                 ';
  MinorName [OvWMode] :=        'OverWrite                               ';

  DefiningMacro := false;	(* We are not initially defining a macro *)

  UsingTabs := true;		(* We will use tabs for indentation *)

  TahType := NoTahArg;		(* No type-ahead arguments *)

  BlockILevel := 2;		(* Default block indent level *)

  FillColumn := 70;		(* Fill column is 70, initially *)
  FuncCount := 0;		(* Reset the function count *)
  KillIndex := -1;		(* Reset count of last kill *)
  DownIndex := -1;		(* Reset count of last up/down function *)

  CommColumn   [FunMode]    := 32;
  CBeginString [FunMode]    := ';                                       ';
  CBeginLength [FunMode]    := 1;
  CEndString   [FunMode]    := '                                        ';
  CEndLength   [FunMode]    := 0;
  Indenters    [FunMode]    := [];
  Exdenters    [FunMode]    := [];
  TabTable     [FunMode]    := FToTabStop;
  RubTable     [FunMode]    := FBwdDelChar;

  CommColumn   [TextMode]   := 32;
  CBeginString [TextMode]   := ';                                       ';
  CBeginLength [TextMode]   := 1;
  CEndString   [TextMode]   := '                                        ';
  CEndLength   [TextMode]   := 0;
  Indenters    [TextMode]   := [];
  Exdenters    [TextMode]   := [];
  TabTable     [TextMode]   := FToTabStop;
  RubTable     [TextMode]   := FBwdDelChar;

  CommColumn   [AlgolMode]  := 32;
  CBeginString [AlgolMode]  := '!                                       ';
  CBeginLength [AlgolMode]  := 1;
  CEndString   [AlgolMode]  := ';                                       ';
  CEndLength   [AlgolMode]  := 1;
  Indenters    [AlgolMode]  := [KwBEGIN];
  Exdenters    [AlgolMode]  := [KwEND];
  TabTable     [AlgolMode]  := FIndAlgol;
  RubTable     [AlgolMode]  := FBwdDelHackTab;

  CommColumn   [MacroMode]  := 32;
  CBeginString [MacroMode]  := ';                                       ';
  CBeginLength [MacroMode]  := 1;
  CEndString   [MacroMode]  := '                                        ';
  CEndLength   [MacroMode]  := 0;
  Indenters    [MacroMode]  := [];
  Exdenters    [MacroMode]  := [];
  TabTable     [MacroMode]  := FToTabStop;
  RubTable     [MacroMode]  := FBwdDelChar;

  CommColumn   [PascalMode] := 32;
  CBeginString [PascalMode] := '(*                                      ';
  CBeginLength [PascalMode] := 3;
  CEndString   [PascalMode] := ' *)                                     ';
  CEndLength   [PascalMode] := 3;
  Indenters    [PascalMode] := [KwBEGIN, KwCASE, KwRECORD, KwREPEAT,
				KwCONST, KwTYPE, KwVAR];
  Exdenters    [PascalMode] := [KwEND, KwUNTIL];
  TabTable     [PascalMode] := FIndPascal;
  RubTable     [PascalMode] := FBwdDelHackTab;

  CommColumn   [LispMode]   := 40;
  CBeginString [LispMode]   := ';                                       ';
  CBeginLength [LispMode]   := 1;
  CEndString   [LispMode]   := '                                        ';
  CEndLength   [LispMode]   := 0;
  Indenters    [LispMode]   := [];
  Exdenters    [LispMode]   := [];
  TabTable     [LispMode]   := FIndForLisp;
  RubTable     [LispMode]   := FBwdDelHackTab;
 
  CommColumn   [CMode]      := 32;
  CBeginString [CMode]      := '/*                                      ';
  CBeginLength [CMode]      := 3;
  CEndString   [CMode]      := ' */                                     ';
  CEndLength   [CMode]	    := 3;
  Indenters    [CMode]	    := [];
  Exdenters    [CMode]	    := [];
  TabTable     [CMode]      := FIndC;
  RubTable     [CMode]      := FBwdDelHackTab;

  CommColumn   [TeXMode]    := 32;
  CBeginString [TeXMode]    := '%                                       ';
  CBeginLength [TeXMode]    := 2;
  CEndString   [TeXMode]    := '                                        ';
  CEndLength   [TeXMode]    := 0;
  Indenters    [TeXMode]    := [];
  Exdenters    [TeXMode]    := [];
  TabTable     [TeXMode]    := FToTabStop;
  RubTable     [TeXMode]    := FBwdDelHackTab;

  CommColumn   [AdaMode]    := 32;
  CBeginString [AdaMode]    := '--                                      ';
  CBeginLength [AdaMode]    := 3;
  CEndString   [AdaMode]    := '                                        ';
  CEndLength   [AdaMode]    := 0;
  Indenters    [AdaMode]    := [KwACCEPT, KwBEGIN, KwCASE, KwELSE, KwEXCEPTION,
				KwLOOP, KwRECORD, KwSELECT, KwTHEN];
  Exdenters    [AdaMode]    := [KwEND, KwELSE, KwELSIF, KwEXCEPTION];
  TabTable     [AdaMode]    := FIndAda;
  RubTable     [AdaMode]    := FBwdDelHackTab;

  CommColumn   [ModulaMode] := 32;
  CBeginString [ModulaMode] := '(*                                      ';
  CBeginLength [ModulaMode] := 3;
  CEndString   [ModulaMode] := ' *)                                     ';
  CEndLength   [ModulaMode] := 3;
  Indenters    [ModulaMode] := [KwBEGIN, KwCASE, KwDO, KwELSE,
				KwLOOP, KwREPEAT, KwTHEN];
  Exdenters    [ModulaMode] := [KwEND, KwELSE, KwELSIF, KwUNTIL];
  TabTable     [ModulaMode] := FIndModula;
  RubTable     [ModulaMode] := FBwdDelHackTab;

  CommColumn   [PL1Mode]    := 32;
  CBeginString [PL1Mode]    := '/*                                      ';
  CBeginLength [PL1Mode]    := 3;
  CEndString   [PL1Mode]    := ' */                                     ';
  CEndLength   [PL1Mode]    := 3;
  Indenters    [PL1Mode]    := [KwBEGIN, KwDO, KwPROCEDURE, KwSELECT];
  Exdenters    [PL1Mode]    := [KwEND];
  TabTable     [PL1Mode]    := FIndPL1;
  RubTable     [PL1Mode]    := FBwdDelHackTab;

  CommColumn   [BlissMode]  := 32;
  CBeginString [BlissMode]  := '!                                       ';
  CBeginLength [BlissMode]  := 2;
  CEndString   [BlissMode]  := '                                        ';
  CEndLength   [BlissMode]  := 0;
  Indenters    [BlissMode]  := [KwBEGIN];
  Exdenters    [BlissMode]  := [KwEND];
  TabTable     [BlissMode]  := FIndBliss;
  RubTable     [BlissMode]  := FBwdDelHackTab;

  UnKillMark := 0;
  UnKillDot := 0;

  UndoBuffer := 0;		(* Nothing to Undo yet *)

  ZeroMacro := nil;
  ZeroChar := nil;
end;

procedure GetFSpec(var FileName: string; FileNumber: integer); external;
function  Chars(D: integer): integer; external;
procedure ChgCase(Argument :integer; FirstUpper, RestUpper :boolean); external;
procedure ChgRegion(UpperCase: boolean); external;
procedure CountLines(AllBuffer: boolean); external;
procedure GetRegion(var First,Last: bufpos); external;
function  GetQName: integer; external;
function  Sentences(D: integer): integer; external;
procedure StripSOSNumbers; external;	(* To strip line numbers *)
function  Words(D: integer): integer; external;
function  Blank(Direction: integer): integer; external;
function  BlankLines(Direction: integer; After: boolean): integer;
  external;
procedure DelHorSpace(Direction: integer); external;
procedure TrmBeep; external;
procedure ModeString(S: string); external;
procedure EchoString(S: string); external;
procedure EchoArrow(C: char); external;
procedure EchoDec(I: integer); external;
procedure EchoOct(I: integer); external;
function  StrLength(var Str: string): integer; external;

procedure KbdStart(Arg: integer); external;
procedure KbdEnd(Arg: integer; ArgGiven: boolean); external;
procedure KbdExecute(Number, Arg: integer); external;
procedure KbdQuery; external;
procedure KbdView(Number: integer); external;
function  KbdRunning: boolean; external;
function  KbdStop: boolean; external;	
function  KbdFreeze: integer; external;

procedure TTyInit; external;
procedure TTyWrite(C: char); external;
procedure TTyHacker(Meta: boolean); external;
function  TTyMeta: boolean; external;
function  TTyProtocol: boolean; external;
procedure XonXoff(Newstate: boolean); external;
procedure Monitor; external;
function  PPush(BChar: integer): boolean; external;
procedure RunCom(FileName, ModeName: string); external;
procedure Detach; external;
procedure DayTime(var L: string); external;
procedure UsrName(var L: string); external;
procedure GetVersion(var S: string); external;
 
procedure BufInit; external;
procedure SwapRegions(P1, P2, P3, P4: bufpos); external;
procedure SetBuf(Number: integer); external;
function  CreateBuf: integer; external;
procedure killbuf(n: integer); external;
function  BufSearch(S: string; SLen, I: integer; Interval: bufpos): boolean;
            external;
procedure Insert(C: char); external;
procedure NInsert(c: char; n: integer); external;
procedure InsBlock(P: dskbp; Count: integer); external;
procedure InsEOL; external;
procedure InsString(s: string); external;
function  AtEOL(Dot: bufpos; Direction: integer): boolean; external;
function  EOLSize: integer; external;
procedure Delete(I: integer); external;
procedure Kill(I: integer); external;
procedure KillPush; external;
procedure UnKill(Offset: integer); external;
procedure KillPop; external;
function  GetModified: boolean; external;
procedure SetModified(M: boolean); external;
function  GetDot: bufpos; external;
procedure SetDot(I: bufpos); external;
function  GetSize: bufpos; external;
function  GetChar(I: bufpos): char; external;
function  GetNull(I: bufpos): char; external;
procedure GetBlock(Pos: bufpos; P: dskbp); external;
function  GetLine(I: integer): bufpos; external;
function  EndLine: bufpos; external;

procedure QG(QReg: integer); external;
procedure QX(QReg: integer; Offset: bufpos); external;
procedure QCopy(From, Too: integer); external;
procedure SetFile; external;

procedure ScrInit(Total: boolean); external;
function  WinTop: bufpos; external;
procedure WinUpDate; external;
procedure WinRefresh; external;
procedure WinReWrite(N: integer); external;
procedure WinPos(Row: integer); external;
procedure WinScroll(N: integer); external;
procedure WinOvClear; external;
procedure WinOvTop; external;
procedure WinOverWrite(C: char); external;
procedure WinSize(var Y, X: integer); external;
procedure WinNo(Number: integer); external;
procedure WinSelect(Number: integer); external;
procedure WinGrow(Lines: integer); external;
function  WinCur: integer; external;
procedure DotPos(var Y, X: integer); external;
function  PosDot(X: integer): integer; external;
procedure PcntMessed; external;
procedure ModeWrite(C: char); external;
procedure ModeClear; external;
procedure ModePos(Y, X: integer); external;
procedure ModeWhere(var Y, X: integer); external;
procedure ModeTime; external;
procedure EchoWrite(C: char); external;
procedure EchoUpdate; external;
procedure EchoEOL; external;
procedure EchoPos(Y, X: integer); external;
procedure EchoWhere(var Y, X: integer); external;
procedure EchoSize(var Y, X: integer); external;

procedure TrmInit; external;
procedure TrmFreeze; external;

procedure InInit(Total: boolean); external;
function  ReadC: char; external;
function  MetaBit: boolean; external;
procedure Flush; external;
function  Check(Seconds: integer): boolean; external;
function  QReadC: char; external;
procedure GetCsiData(var arg: integer; var tc: char); external;
procedure ReRead; external;
procedure AutoChar(C: char); external;
procedure AutoLast(expand: boolean); external;
procedure AutoImmediate; external;
procedure AutoReset; external;
procedure EchoClear; external;
 
function  Catch(var Context: catchblock): boolean; external;
procedure Throw(var Context: catchblock); external;
 
procedure OvWDec(I: integer); external;
procedure OvWString(S: string); external;
procedure OvWLine; external;
procedure ReadDefault(Prompt, Default: string; var S: string;
		      var Len: integer; FileFlag: boolean); external;
procedure ReadLine(Prompt: string; var S: string; var Len: integer); external;
procedure ReadFName(Prompt: string; var S: string; var Len: integer); external;
function  YesOrNo: boolean; external;
function  SpaceOrTab(C: char): boolean; external;
function  StrCompare(S1, S2: string): integer; external;
procedure ExpTabs(Dir: integer); external;
function  HorPos: integer; external;

procedure DskInit; external;
function  DskOpen(FileName: string; Access: char): integer; external;
procedure TrueName(var NamStr: string; Fields: char); external;
function  TrueMode: majors; external;
procedure TruePos(var PageNumber, LineNumber, CharNumber: bufpos); external;
procedure DskMessage(var ErrStr: string); external;
function  DskRead(var P: dskbp): integer; external;
function  DskNext: dskbp; external;
function  DskWrite(Count: integer): integer; external;
function  DskClose: integer; external;
function  GetParameters: boolean; external;
function  DskCD(directory: string): integer; external;

function  LsFOpen(s: string; i: integer): integer; external;
function  LsFMore: boolean; external;
function  LsFChar: char; external;
function  LsFClose: integer; external;

procedure SeaInit(Total: boolean); external;
procedure IncrementalSearch(Incremental: boolean; SearchArg: integer);
            external;
procedure QueryReplace(Query, Delimitered: boolean); external;
procedure HowMany; external;
procedure Occur; external;
 
procedure GetPOM(var POMString: string); external;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure TopLoop;		(* Return to top loop, via non-local goto *)
begin
  TrmBeep;			(* Beep the terminal, to notify user. *)
  DskInit;			(* Reinitialize DSKIO. *)
  BVoid := KbdStop;		(* Stop a running keyboard macro. *)
  PcntMessed;			(* Tell WINDOW to redisplay the percentage. *)
  EchoClear;			(* Clear the echo area. *)
  EchoUpdate;			(* Force echo area updating. *)
  Throw(Err);			(* Do a non local GOTO to some place. *)
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure Error(Message: string);
begin
  TrmBeep;			(* Beep the terminal, to notify user. *)
  DskInit;			(* Reinitialize DSKIO. *)
  WinOvClear;			(* Clear overwrite mode for WINDOW. *)
  BVoid := KbdStop;		(* Stop a running keyboard macro. *)
  TahType := NoTahArg;		(* Clear type-ahead arguments *)
  EchoClear;			(* Clear the echo area. *)
  EchoString(Message);		(* Write the message. *)
  PcntMessed;			(* Tell WINDOW to redisplay the percentage. *)
  Flush;			(* Flush terminal input buffer. *)
  WinUpdate;			(* Update echo area and window. *)
  CVoid := QReadC;		(* Wait for user to type a command. *)
  ReRead;			(* Don't use the command character. *)
  EchoClear;			(* Clear the echo area. *)
  EchoUpdate;			(* Force echo area updating. *)
  Throw(Err);			(* Do a non local GOTO to some place. *)
end;

(*---------------------------------------------------------------------------*)
(* NotYetError tells the user that a command is not yet implemented.	     *)

(* ==> UTILITY *)

(*@VMS: [global] *)
procedure NotYetError;
begin
  Error('NYI? Function is Not Yet Implemented    ');
end;

(*---------------------------------------------------------------------------*)
(* SetCharacters sets up the variables controlling what characters are       *)
(* considered letters, delimiters, parens and such.                          *)

procedure SetCharacters;
begin
  Uppers := ['A'..'Z'];
  Lowers := ['a'..'z'];
  (*@VMS: Uppers := Uppers + [chr(192)..chr(207), chr(209)..chr(221)]; *)
  (*@VMS: Lowers := Lowers + [chr(224)..chr(239), chr(241)..chr(253)]; *)
  if SwedMode in MinorModes then begin
    Uppers := Uppers + ['[', '\', ']'];
    Lowers := Lowers + ['{', '|', '}'];
  end;
  Letters := Uppers + Lowers;
  (*@VMS: Letters := Letters + [chr(223)]; *)
  Quotes := [];
  case MajorMode of
FunMode:
    begin
      Alphas := ['$', '%', '.'];
      Lparens := ['(', '[', '{'];
      Rparens := ['}', ']', ')'];
    end;
TextMode:
    begin
      Alphas := ['_', ''''];
      Lparens := [(*@VMS: chr(171) *)];
      Rparens := [(*@VMS: chr(187) *)];
    end;
AlgolMode:
    begin
      Alphas := ['_'];
      Lparens := ['(', '['];
      Rparens := [']', ')'];
      Quotes := ['"', ''''];
    end;
MacroMode:
    begin
      (*@VMS:  Alphas := ['$', '_', '.']; *)
      (*@TOPS: Alphas := ['$', '%', '.']; *)
      Lparens := ['(', '[', '<', '{'];
      Rparens := ['}', '>', ']', ')'];
    end;
PascalMode:
    begin
      Alphas := ['_' (*@VMS: , '$' *)];
      Lparens := ['(', '[', '{'];
      Rparens := ['}', ']', ')'];
      Quotes := [''''];
    end;
LispMode:
    begin
      Alphas := ['!'..'z'] - ['(', ')', '/', ''''];
      Lparens := ['('];
      Rparens := [')'];
    end;
CMode:
    begin
      Alphas := ['_'];
      Lparens := ['(', '[', '{'];
      Rparens := ['}', ']', ')'];
      Quotes := ['"', ''''];
    end;
TeXMode:
    begin
      if SwedMode in MinorModes then begin
	Lparens := ['<'];
	Rparens := ['>'];
      end else begin
	Lparens := ['{'];
	Rparens := ['}'];
      end;
      Alphas := [];
    end;
AdaMode:
    begin
      Alphas := ['_'];
      Lparens := ['('];
      Rparens := [')'];
      Quotes := ['"'];
    end;
ModulaMode:
    begin
      Alphas := ['_' (*@VMS: , '$' *)];
      Lparens := ['(', '[', '{'];
      Rparens := ['}', ']', ')'];
      Quotes := ['''', '"'];
    end;
PL1Mode:
    begin
      Alphas := ['_' (*@VMS: , '$' *)];
      Lparens := ['(', '[', '{'];
      Rparens := ['}', ']', ')'];
      Quotes := [''''];
    end;
BlissMode:
    begin
      Alphas := ['_', '%', '$'];
      Lparens := ['(', '[', '<'];
      Rparens := ['>', ']', ')'];
      Quotes := [''''];
    end;
  end; (* case *)
  Lparens := Lparens - Letters;
  Rparens := Rparens - Letters;
  Alphas := Alphas + Letters + ['0'..'9'];
end;

(*---------------------------------------------------------------------------*)
(* SetMajor stores a new major mode into the global variable and file name   *)
(* block, and reassignes some functions, if necessary.			     *)

procedure SetMajor(Mode: majors);
begin
  DispTab [HorizontalTab] := TabTable [Mode];
  DispTab [RubOut] := RubTable [Mode];
  MajorMode := Mode;		(* Store new major mode into global variable *)
  CurrName^.MajorMode := MajorMode; (* and file name block. *)
  ModeChanged := true;		(* Mode line might need updating. *)
  SetCharacters;
end;

(*---------------------------------------------------------------------------*)
(* SetMinor stores new minor modes into the global variable and file name    *)
(* block, and reassignes some functions, if necessary.			     *)

procedure SetMinor(Mode: setofminors);
begin
  if FillMode in Mode
  then DispTab[Ord(' ')] := FFillSpace
  else DispTab[Ord(' ')] := FSelfInsert;
  MinorModes := Mode;
  CurrName^.MinorModes := MinorModes;
  ModeChanged := true;
  SetCharacters;
end;

(*---------------------------------------------------------------------------*)

procedure SelBuffer(NewName: refname);
begin
  PrevName := CurrName;		(* Remember previous buffer *)
  CurrName := NewName;		(* Select new buffer *)
  with CurrName^ do begin
    SetBuf(Number);
    SetMajor(MajorMode);
    SetMinor(MinorModes);
  end; (* with *)
end;

(*---------------------------------------------------------------------------*)
(*  This routine searches for a buffer, given its number.                    *)

function NumFBuffer(goal: integer): refname;
var Test, Match: refname;
begin
  Test := ZeroName^.Right;
  Match := nil;
  while (Test <> ZeroName) and (Match = nil) do begin
    if Goal = Test^.Number
    then Match := Test
    else Test := Test^.Right;
  end;
  if Match = nil then error('NSB? No such buffer                     ');
  NumFBuffer := Match;
end;

(*---------------------------------------------------------------------------*)
(*  This routine creates a new buffer, and links it into our buffer list.    *)

function CreBuffer(str: string): refname;
var
  x: refname;
  i: integer;
begin
  New(x);
  with x^ do begin
    Left := ZeroName^.Left;
    Right := ZeroName;
    Number := CreateBuf;
    Name := Str;
    NoFileName := true;
    ReadOnly := false;
    MajorMode := FunMode;
    MinorModes := [];
    MarkPos := 0;
    for i := 0 to MarkSize do MarkRing[i] := 0;
  end; (* with x^ *)
  ZeroName^.Left^.Right := x; (* Insert buffer into linked list *)
  ZeroName^.Left := x;
  CreBuffer := x;
end;

(*---------------------------------------------------------------------------*)

function StrFBuffer(str: string; create: boolean): refname;
var Test, Match: refname;
begin
  Test := ZeroName^.Right;
  Match := nil;
  while (Test <> ZeroName) and (Match = nil) (* Scan forward for buffer *)
  do begin
    if StrCompare(str, Test^.Name) = 0
    then Match := Test
    else Test := Test^.Right;
  end;
  if Match = nil then begin	(* Found any buffer? *)
    if not create then Error('NSB? No such buffer                     ');
    Match := CreBuffer(str);	(* Nope, create a new buffer with that name. *)
  end;
  StrFBuffer := Match;
end;

(*---------------------------------------------------------------------------*)
(*  This function will prompt the user for a buffer name, and return a       *)
(*  pointer to that buffer, creating it if told to do so.		     *)

function AskBuffer(prompt: string; default: refname; create: boolean): refname;
var
  NameStr: string;
  NameLen: integer;
begin
  if default <> nil
  then ReadDefault(prompt, default^.Name, NameStr, NameLen, false)
  else ReadLine(prompt, NameStr, NameLen);
  EchoClear;
  if NameLen = 0
  then AskBuffer := default
  else AskBuffer := StrFBuffer(NameStr, create);
end;

(*---------------------------------------------------------------------------*)
(*  This procedure implements the function "Rename Buffer".                  *)

procedure RenBuffer;
begin
  EchoClear;			(* Clear out echo area *)
  ReadLine('Rename Buffer:                          ', CurrName^.Name, IVoid);
  EchoClear;			(* Clear out dialouge *)
  ModeChanged := true;		(* We sure have changed the mode line *)
end;

(*---------------------------------------------------------------------------*)
(*  This procedure implements the function "List Buffers".                   *)

procedure ListBuffers;
var
  ShowName: refname;
  Pos: integer;
begin
  OvWString('  #  Buffer  (Mode)  Filename           '); OvWLine;
  OvWString('  (* means buffer needs saving)         '); OvWLine;
  OvWLine;
  ShowName := ZeroName^.Right;
  while ShowName <> ZeroName
  do
  with ShowName^ do begin
    SetBuf(Number);
    if GetModified
    then WinOverWrite('*')
    else WinOverWrite(' ');
    WinOverWrite(' ');
    OvWDec(Number);
    if Number <= 9
    then WinOverWrite(' ');
    WinOverWrite(' ');
    OvWString(Name);
    WinOverWrite(' ');
    WinOverWrite('(');
    for Pos := 1 to StrSize
    do
    if MajorName[MajorMode][Pos] <> ' '
    then WinOverWrite(MajorName[MajorMode][Pos]);
    WinOverWrite(')');
    WinOverWrite(' ');
    WinOverWrite(' ');
    if NoFileName
    then begin
      OvWDec(GetSize);
      OvWString(' Characters                             ')
    end
    else OvWString(FileName);
    OVWLine;
    ShowName := Right;
  end (* while *);
  SetBuf(CurrName^.Number);
end;

(*---------------------------------------------------------------------------*)
(* OtherBuffer selects other window's buffer.				     *)

procedure OtherBuffer;
var
  CopyCurrName, CopyPrevName: refname;
begin
  CopyCurrName := CurrName;
  CopyPrevName := PrevName;
  if OtherName = nil
  then SelBuffer(StrFBuffer('W2                                      ', true))
  else SelBuffer(OtherName);
  OtherName := CopyCurrName;
  PrevName := CopyPrevName;
end;

(*---------------------------------------------------------------------------*)
(*  Get current mark (and pop).						     *)

(*@VMS: [global] *)
function GetMark(Pop: boolean): bufpos;
begin
  with CurrName^ do begin
    GetMark := MarkRing[MarkPos]; (* Load value of current mark from ring. *)
    if Pop
    then MarkPos := (MarkPos + MarkSize) mod (MarkSize + 1);
  end;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure SetMark(Mark: bufpos);
begin
  with CurrName^ do begin
    MarkPos := (MarkPos + 1) mod (MarkSize + 1);
    MarkRing[MarkPos] := Mark;
  end;
end;

(*---------------------------------------------------------------------------*)

procedure AllowUndo;
begin
  QX(UndoRegister, GetMark(false) - GetDot); (* Save region in undo register *)
  UndoBuffer := Currname^.Number; (* Save the buffer number *)
  UndoFunction := LastFunc;	(* Remember the function *)
end;

(*---------------------------------------------------------------------------*)

procedure ModeLine;
var
  minor: minors;

  procedure ModeBack;
  var row, col: integer;
  begin
    ModeWhere(row, col);
    ModePos(row, col - 1);
  end;

begin (* ModeLine *)		(* Update the mode line *)
  ModeClear;			(* Clear mode area and go to start *)
  if RecLevel <= 1		(* Normal editing level *)
  then begin
    ModeString('AMIS                                    '); 
    ModeTime;			(* Put a digital clock here *)
    ModeWrite(' ');		(* And a space after it *)
    ModeWrite('(');
    ModeString(MajorName[MajorMode]);	(* Write major mode name *)
    for Minor := FirstMinor to LastMinor
    do
    if Minor in MinorModes
    then ModeString(MinorName[Minor]);
    if DefiningMacro
    then ModeString('Def                                     ');
    ModeBack;			(* Go back over last space. *)
    ModeWrite(')');
    ModeWrite(' ');
    ModeString(CurrName^.Name);
    ModeBack;
    ModeWrite(':');
    ModeWrite(' ');
    if not CurrName^.NoFileName then begin
      ModeString(CurrName^.FileName);
      if CurrName^.ReadOnly
      then ModeString('(RO)                                    ');
    end; (* if *)
  end else begin		(* Recursive editing level *)
    ModeWrite('[');
    ModeString(RecName);
    ModeBack;
    ModeWrite(']');
  end; (* if *)
end;
 
(*---------------------------------------------------------------------------*)
(*  This routine is used by INPUT when the kbd macro "define" state changes. *)

(*@VMS: [global] *)
procedure DefMode(flag: boolean);
begin
  DefiningMacro := flag;
  ModeChanged := true;
end;

(*---------------------------------------------------------------------------*)

procedure Refresh;
begin				(* Refresh window, mode line etc. *)
  EchoClear;			(* Clear the echo area internally *)
  WinRefresh;			(* Tell window to refresh *)
end;
 
(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
function Letter(c: char): boolean;
begin
  Letter := c in Letters;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
function Delim(C: char): boolean;
begin
  Delim := not (c in Alphas);
end;	

(*---------------------------------------------------------------------------*)
(* UpCase upcases an English or Swedish letter, according to Swedish Mode.   *)

(*@VMS: [global] *)
function UpCase(c: char): char;
begin
  if c in Lowers then c := chr(ord(c) - ord('a') + ord('A'));
  UpCase := c;
end;
 
(*---------------------------------------------------------------------------*)
(* DownCase downcases an English or Swedish letter.			     *)

(*@VMS: [global] *)
function DownCase(c: char): char;
begin
  if c in Uppers then c := chr(ord(c) - ord('A') + ord('a'));
  DownCase := c;
end;

(*---------------------------------------------------------------------------*)

procedure DiskCheck(Code: integer);
var Msg: string;
begin
  if Code = DskFatal then	(* Make sure we have an error *)
  begin
    DskMessage(Msg);		(* Get the error string *)
    Error(Msg);
  end;
end;

(*---------------------------------------------------------------------------*)

(* ==> UTILITY *)

procedure GiveDocumentation(S: string);
var
  I, J	: integer;
  C: char;
  Pos: integer;
  Str: string;
  BlockCount: integer;
  BlockPointer: dskbp;
  BlockSize: integer;
  MoreDoc  : boolean;
  Searching: boolean;

  procedure DocError;		(* Bombs out on I/O errors *)
  begin (*DocError*)
    error('CFD? Can''t find documentation           ');
  end (*DocError*);

  function NextChar: char;
  begin (*NextChar*)
    BlockCount := BlockCount + 1;
    while BlockCount > BlockSize do begin
      BlockSize := DskRead(BlockPointer);
      if BlockSize < 0
      then DocError;
      BlockCount := 1;
    end;
    NextChar := BlockPointer^[BlockCount];
  end (*NextChar*);

begin (*GiveDocumenatation*)
  GetFSpec(Str, 4);		(* TED:AMIS.DXC *)
  if DskOpen(Str, 'R') <> 0
  then DocError;		(* If we can't open the file, bomb out *)
  BlockCount := 0;
  BlockSize := 0;
  C := NextChar;
  Searching := true;
  while Searching do begin
    Pos := 0;
    while C <> Chr(CarriageReturn) do begin
      Pos := Pos + 1;
      if Pos <= StrSize then Str[Pos] := C;
      C := NextChar;
    end;
    C := NextChar;		(* Eat the line feed... *)
    C := NextChar;		(* .. and get next char to use *)
    for I := Pos + 1 to StrSize do Str[I] := ' ';
    if StrCompare(Str, S) = 0 then begin
      Searching := false;	(* We found it now... *)
      WinOvTop;			(* Start at upper left corner *)
      J := StrLength(S);
      for I := 1 to J do WinOverWrite(S[I]);
      WinOverWrite(':');
      OvWLine;
      MoreDoc := true;
      while MoreDoc do begin
	while SpaceOrTab(C) do C := NextChar; (* Eat indentation *)
	MoreDoc := C <> Chr(CarriageReturn);
	while C <> Chr(CarriageReturn) do begin
	  WinOverWrite(C);
	  C := NextChar
	end;
	C := NextChar; C := NextChar; (* Eat crlf *)
	OvWLine
      end;
      OvWLine
    end else begin
      MoreDoc := true;
      while MoreDoc do begin
	while SpaceOrTab(C) do C := NextChar; (* Eat indentation *)
	MoreDoc := C <> Chr(CarriageReturn);
	while C <> Chr(CarriageReturn) do C := NextChar;
	C := NextChar; C := NextChar;
      end;
    end (*Skipping wrong description*)
  end (*while searcing*);
  DiskCheck(DskClose)
end (*GiveDocumenatation*);

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
function GetTahString(var S: string; var Len: integer): boolean;
begin
  case TahType of
  NoTahArg:
    GetTahString := false;
  OneTahArg:
    begin
      S := TahStr1; Len := TahLen1;
      TahType := NoTahArg;
      GetTahString := true
    end;
  TwoTahArgs:
    begin
      S := TahStr1; Len := TahLen1;
      TahStr1 := TahStr2; TahLen1 := TahLen2;
      TahType := OneTahArg;
      GetTahString := true
    end;
  end (*case*)
end;

(*---------------------------------------------------------------------------*)

function CaseCheck(Index: integer): fcode;
var
  f: fcode;
  c: char;
begin
  c := chr(Index mod 256);	(* Remove control and meta bits *)
  f := DispTab[Index];		(* Get our fcode *)
  if f = FIllegal then begin
    if c in ['A'..'Z'] then Index := Index + 32;
    if c in ['a'..'z'] then Index := Index - 32;
    if c < ' ' then begin
      if Index < 512
      then Index := Index + 512 + 64 (* Map M-^X to C-M-X *)
      else Index := Index + 64;	(* Map C-M-^X to C-M-X too *)
    end;
    f := DispTab[Index];
  end;
  CaseCheck := f;
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure ReMap(var c: char; search: boolean);
var
  i: integer;
  f: fcode;
  tc: char;
begin
  f := CaseCheck(ord(c));	(* Get primary dispatch entry. *)
  if f = FCSISequence then begin
    GetCsiData(i, tc);
    if (tc = '~') and (i >= 0) and (i <= 35)
    then f := TildeTable[i]
    else f := VTTable[ord(tc) mod 128];
  end;
  if f = FQInsert then c := chr(CtrlQ);
  if f = FDocumentation then c := chr(HelpChar);
  if search then begin
    if f = FRSearch then c := chr(CtrlR);
    if f = FISearch then c := chr(CtrlS);
  end;
end;

(*---------------------------------------------------------------------------*)

(* ==> UTILITY *)

(*@VMS: [global] *)
procedure DoCtlW(var Line: string; var Pos: integer);
label 9;
var
  c: char;
  letters: set of char;
begin
  if Pos <= 0 then goto 9;	(* Done if line is empty. *)
  c := Line[Pos];		(* Get last char in string. *)
  Pos := Pos - 1;		(* Back one step. *)
  if Pos <= 0 then goto 9;	(* If this was the only char, done. *)
  letters := ['A'..'Z', 'a'..'z', '0'..'9'];
  if c in letters then repeat
    if not (Line[Pos] in letters) then goto 9;
    Pos := Pos - 1;
  until Pos = 0
  else if SpaceOrTab(c) then repeat
    if not SpaceOrTab(Line[Pos]) then goto 9;
    Pos := Pos - 1;
  until Pos = 0;
  9:
end;

(*---------------------------------------------------------------------------*)

function ReadFunc: fcode;	(* Read a function name from terminal *)
var				(* with recognition and all that stuff *)
  C		: char;		(* Scratch *)
  I		: integer;	(* Scratch *)
  Line		: string;	(* The line we are reading in *)
  LCount	: integer;	(* Count of characters in Line *)
  Match		: string;	(* The longest matching string *)
  MCount	: integer;	(* Count of characters in Match *)
  F		: fcode;	(* Scratch *)
  FoundCount	: integer;	(* Used by some routines, nearly scratch *)
  Goal		: fcode;	(* Goal function *)
  StartRow,StartCol: integer;	(* Position where prompter ends *)
  SS1, SS2	: string;	(* Used for type-ahead arguments *)
  LS1, LS2	: integer;	(* Used for lengths of SS1 & SS2 *)
  State	: (ReadName, FirstArg, SecondArg); (* What are we reading in? *)

  procedure MergeLine(S: string);
  var
    I: integer;
  begin
    if FoundCount = 0
    then begin
      Match := S; MCount := strsize
    end
    else begin
      I := LCount;		(* Hack to save some time *)
      while (I <= strsize) and (UpCase(Match[I]) = UpCase(S[I])) do I := I + 1;
      MCount := I - 1
    end;
    FoundCount := FoundCount + 1
  end;

  function PartMatch(S1, S2: string; Len: integer): boolean;
  label 9;
  var I: integer;
  begin
    PartMatch := false;		(* Assume no match *)
    for I := 1 to Len do	(* Then look at the strings *)
    if UpCase(S1[I]) <> UpCase(S2[I]) then goto 9;
    PartMatch := true;		(* Come here only if substrings are equal *)
  9:
  end;

  procedure RePaint;		(* RePaint restores the echo line *)
  var I	: integer;
  begin
    EchoPos(StartRow,StartCol);
    for I := 1 to LCount do EchoArrow(Line[I]);
    if (State = FirstArg) or (State = SecondArg)
    then begin			(* We have an string arg going on... *)
      EchoArrow('$');		(* Echo the delimiting dollar sign *)
      for I := 1 to LS1 do EchoArrow(SS1[I]) (* Echo the string *)
    end;
    if State = SecondArg
    then begin			(* We got a second arg too *)
      EchoArrow('$');		(* Yet another delimiting dollar sign *)
      for I := 1 to LS2 do EchoArrow(SS2[I]); (* Echo second string *)
    end;
    EchoEOL			(* Finally, erase rest of line *)
  end;

  procedure InsChr(Ch: char);
  begin
    case State of
    ReadName:
      if LCount = StrSize	(* Attempting to insert to much? *)
      then TrmBeep		(* Beep the user *)
      else begin
	LCount := LCount + 1;	(* Bump character counter *)
	Line[LCount] := Ch;	(* Store the character *)
	EchoArrow(Ch)		(* Echo the character *)
      end;
    FirstArg:
      if LS1 = StrSize
      then TrmBeep
      else begin
	LS1 := LS1 + 1;		(* Bump character counter *)
	SS1[LS1] := Ch;		(* Store character *)
	EchoArrow(Ch)		(* Echo it *)
      end;
    SecondArg:
      if LS2 = StrSize
      then TrmBeep
      else begin
	LS2 := LS2 + 1;		(* Bump character counter *)
	SS2[LS2] := Ch;		(* Store character *)
	EchoArrow(Ch)		(* Echo it *)
      end;
    end (*case*);
  end (*InsChr*);

  procedure GiveHelp;
  var I: integer;
  begin
    WinOvTop;
    if State = ReadName		(* If we are inside function name... *)
    then begin
      OvWString('You are typing in the name of an AMIS   ');
      OvWString('extended command.                       ');
      OvWLine;
      OvWString('Use Rubout to delete previous           ');
      OvWString('characters;                             ');
      OvWString('use ^U to delete the whole thing.       ');
      OvWLine;
      OvWString('Typing Space or Escape causes as much   ');
      OvWString('of the command name as possible to be   ');
      OvWLine;
      OvWString('filled in for you (this is called       ');
      OvWString('command completion).                    ');
      OvWLine;
      OvWString('Type ? to list all the command names    ');
      OvWString('which match what you have typed.        ');
      OvWLine;
      OvWString('If completion fills in the entire name, ');
      OvWString('a Dollar sign ($) appears.              ');
      OvWLine;
      OvWString('You can then start typing the arguments ');
      OvWString('to the command.                         ');
      OvWLine;
      OvWString('Terminate them with a Return.  If there ');
      OvWString('are no arguments,                       ');
      OvWLine;
      OvWString('you can use Return after a sufficient   ');
      OvWString('abbreviation.                           ');
      OvWLine
    end else begin		(* If in argument part, document function *)
      for I :=  LCount+1 to StrSize do Line[I] := ' ';
      GiveDocumentation(Line)	(* Document the function named "line" *)
    end;
  end (*GiveHelp*);

  procedure ListMatches;
  var
    MacIndex: refmacro;	(* Index for kbd macro names *)
    S	    : string;		(* Scratch *)
    F	    : fcode;		(* Scratch *)
  begin (** ListMatches **)
    WinOvTop;			(* Start at top left corner *)
    MacIndex := ZeroMacro;	(* Points to first keybord macro *)
    while MacIndex <> nil
    do begin
      if PartMatch(MacIndex^.Name, Line, LCount)
      then begin
	OvwString(MacIndex^.Name); OvwLine
      end;
      MacIndex := MacIndex^.Next; (* Bump pointer *)
    end; (*While*)
    for F := Succ(FFirst) to Pred(FLast) do begin
      if PartMatch(FuncName[F], Line, LCount)
      then begin
	OvwString(FuncName[F]); OvwLine
      end;
    end; (*for*)
    OvwLine
  end; (** ListMatches **)

  procedure TryFinish;
  var S	    : string;
    Foo	    : fcode;
    MacIndex: refmacro;
  begin
    FoundCount := 0;		(* We haven't found any matches yet *)
    MacIndex := ZeroMacro;
    while MacIndex <> nil do begin
      if PartMatch(MacIndex^.Name, Line, LCount)
      then begin
	KbdRecMacro := MacIndex; (* Remember the one we found *)
	FoundCount := FoundCount + 1;
	Foo := FMacroExtend;
      end;
      MacIndex := MacIndex^.Next; (* Bump pointer *)
    end; (*while*)
    for F := Succ(FFirst) to Pred(FLast) do begin
      if PartMatch(FuncName[F], Line, LCount)
      then begin
        FoundCount := FoundCount + 1;
        Foo := F
      end;
    end; (*for*)
    if FoundCount = 1		(* Exactly one match? *)
    then Goal := Foo		(* Yes, break and give it back *)
    else TrmBeep		(* No, beep user *)
  end;

  procedure Recognite(BreakOnSpace: boolean);
  label 9;
  var
    MacIndex: refmacro;
    i: integer;
    c: char;
    f: fcode;
  begin
    if Lcount = 1 then begin
      c := Upcase(Line[1]); (* Upper case for testing... *)
      if c = 'I' then begin
	InsChr('n'); InsChr('s'); InsChr('e'); InsChr('r'); InsChr('t');
      end;
      if c = 'L' then begin
	InsChr('i'); InsChr('s'); InsChr('t');
      end;
      if c = 'V' then begin
	InsChr('i'); InsChr('e'); InsChr('w');
      end;
      if c = 'W' then begin
	InsChr('h'); InsChr('a'); InsChr('t');
      end;
    end; (* Lcount = 1 *)
    FoundCount := 0;		(* We haven't found any matches yet *)
    MacIndex := ZeroMacro;
    while MacIndex <> nil do begin
      if PartMatch(MacIndex^.Name, Line, LCount)
      then MergeLine(MacIndex^.Name);
      MacIndex := MacIndex^.Next; (* Bump pointer *)
    end; (*while*)
    for f := Succ(FFirst) to Pred(FLast) do begin
      if PartMatch(FuncName[F], Line, LCount)
      then MergeLine(FuncName[F]);
    end; (*for*)
    if FoundCount = 0		(* Did we find anything? *)
    then TrmBeep		(* No, nothing matches, beep user *)
    else begin			(* Something matches, make up first part *)
      for i := 1 to LCount do Line[I] := Match[I];
      if FoundCount = 1		(* Just one match? *)
      then MCount := StrLength(Match); (* Yes, strip off trailing blanks *)
      for I := LCount + 1 to MCount do begin
	c := Match[I]; Line[I] := c; LCount := I;
	if (c = ' ') and BreakOnSpace then goto 9;
      end;
     9:
      if (FoundCount = 1) and (LCount = MCount)
      then State := FirstArg
    end;
    RePaint;
  end;

begin (** ReadFunc **)
  EchoWhere(StartRow,StartCol);	(* Get initial position *)
  LCount := 0;			(* Reset count *)
  LS1 := 0;			(* Reset arg 1 length *)
  LS2 := 0;			(* Reset arg 2 length *)
  State := ReadName;		(* Set up our state *)
  Goal := FIllegal;		(* And no goal function yet *)
  repeat
    if not Check(0) then EchoUpdate;
    C := ReadC;			(* Read a character *)
    ReMap(c, false);
    if C = Chr(CarriageReturn) then (* Return, look if unambiguos *)
      TryFinish
    else if C = Chr(CtrlQ) then
    begin
      if not Check(0) then EchoUpdate; InsChr(QReadC);
    end
    else if C = Chr(CtrlR) then
    begin
      InsChr('^'); InsChr('R')
    end
    else if C = Chr(CtrlU)
    then begin
      case State of
        ReadName:  LCount := 0;
	FirstArg:  LS1 := 0;
	SecondArg: LS2 := 0;
      end (*case*);
      RePaint
    end
    else if c = chr(CtrlW) then begin
      case State of
	ReadName:  DoCtlW(Line, LCount);
	FirstArg:  DoCtlW(SS1, LS1);
	SecondArg: DoCtlW(SS2, LS2);
      end;
      RePaint;
    end
    else if C = Chr(Escape) then begin
      case State of
      ReadName:			(* In function name, does recognition *)
        Recognite(false);
      FirstArg:			(* In first string, starts second *)
        begin			(* We have to echo the dollar sign ourselves *)
	  State := SecondArg; EchoArrow('$')
	end;
      SecondArg:		(* In second string, self insert *)
        InsChr(C);
      end (*case*)
    end
    else if C = Chr(HelpChar) then
      GiveHelp
    else if C = ' ' then begin
      case State of
      ReadName:			(* In function name, does recognition *)
	begin
	  i := LCount;		(* Save length. *)
	  Recognite(true);	(* Try for recognition. *)
	  if i = LCount then begin (* If nothing did happen... *)
	    if FoundCount > 1 then InsChr(' '); (* Multiple matches. *)
	    if FoundCount = 0 then TrmBeep;	(* No matches. *)
	  end;
	end;
      FirstArg,			(* In string args, self insert *)
      SecondArg:
        InsChr(C);
      end (*case*)
    end
    else if C = '?' then begin
      case State of
      ReadName:
        ListMatches;
      FirstArg,
      SecondArg:
        InsChr('?');
      end (*case*)
    end
    else if C = Chr(RubOut) then
    begin
      case State of
      ReadName:
        if LCount > 0
	then LCount := LCount - 1
	else TrmBeep;
      FirstArg:
        if LS1 > 0
	then LS1 := LS1 - 1
	else State := ReadName;
      SecondArg:
        if LS2 > 0
	then LS2 := LS2 - 1
	else State := FirstArg;
      end (*case*);
      RePaint
    end
    else			(* Only self-inserting characters left *)
      InsChr(C)
  until Goal <> FIllegal;	(* Repeat until we got anything *)
  EchoClear;			(* Clear the echoed line *)
  WinOvClear;			(* Clear window overwrite mode *)
  case State of
  ReadName:
    TahType := NoTahArg;
  FirstArg:
    begin
      for I := LS1+1 to StrSize do SS1[I] := ' ';
      if LS1 = 0
      then TahType := NoTahArg	(* Hack for empty first string *)
      else begin
	TahType := OneTahArg;
	TahStr1 := SS1; TahLen1 := LS1
      end
    end;
  SecondArg:
    begin
      for I := LS1+1 to StrSize do SS1[I] := ' ';
      for I := LS2+1 to StrSize do SS2[I] := ' ';
      TahType := TwoTahArgs;
      TahStr1 := SS1; TahLen1 := LS1;
      TahStr2 := SS2; TahLen2 := LS2
    end;
  end (*case*);
  ReadFunc := Goal		(* Return it *)
end (*ReadFunc*);

(*---------------------------------------------------------------------------*)
(*  This routine reads a command character, with immediate echo.  Used by    *)
(*  Set Key, various helpers and such.                                       *)

function ReadCmdChar: integer;
var
  Prefix: set of prefixes;	(* Prefix of command *)
  Index: integer;
  Done: boolean;
  f: fcode;
begin (* ReadCmdChar *)
  Prefix := [];			(* Clear prefixes. *)
  AutoImmediate;		(* Immediate echo. *)
  repeat
    EchoUpDate;			(* Keep echo area correct. *)
    Done := true;		(* Assume we will do it. *)
    Index := ord(ReadC);	(* Read a character *)
    if MetaBit then Prefix := Prefix + [PfxMeta];
    if PfxControl in Prefix then Index := Index + 512;
    if PfxMeta in Prefix then Index := Index + 256;
    f := CaseCheck(Index);	(* Get corresponding function code *)
    if f = FPfxControl then begin
      Prefix := [PfxControl];
      AutoChar('C'); AutoChar('-');
      Done := false;
    end;
    if f = FPfxMeta then begin
      Prefix := [PfxMeta];
      AutoChar('M'); AutoChar('-');
      Done := false;
    end;
    if f = FPfxCM then begin
      Prefix := [PfxControl, PfxMeta];
      AutoChar('C'); AutoChar('-'); AutoChar('M'); AutoChar('-');
      Done := false;
    end;
  until Done;
  AutoLast(Prefix = []);	(* Auto-echo terminator. *)
  ReadCmdChar := Index;
end; (* ReadCmdChar *)

(*---------------------------------------------------------------------------*)

(* ==> BUFFER *)

function LineSearch(Str: string; Len: integer): boolean;
begin
  LineSearch := false;
  if EndLine <> GetDot then
    LineSearch := BufSearch(Str, Len, 1, EndLine - GetDot)
end;

(*---------------------------------------------------------------------------*)

(* ==> BUFFER *)

function BufSChar(s: setofchar; HowFar: integer): boolean;
label 9;
var
  Base, Dot: bufpos;
begin
  BufSChar := true;
  Base := GetDot;
  for dot := Base-1 downto Base+HowFar do begin
    if GetChar(dot) in s then begin
      SetDot(dot);
      goto 9;
    end;
  end;
  BufSChar := false;
9:
end;

(*---------------------------------------------------------------------------*)

procedure ParMatch;		(* Does the job of matching parens *)
label 9;
var
  Level, Distance: integer;
  Start, Wtop: bufpos;
  Goals: set of char;
  c, lp, rp: char;
begin
  Start := GetDot;		(* Remember where we started *)
  SetDot(Start-1);		(* Go back one character *)
  if (MajorMode = LispMode) or (MajorMode = TeXMode)
  then begin
    if GetNull(Start - 2) = '/' then goto 9;
  end;
  WTop := WinTop;		(* Remember top of window *)
  Goals := Lparens + Rparens + Quotes; (* Look for these. *)
  Level := 1;			(* Nesting level is 1, initially *)
  while Level > 0 do begin
    Distance := WTop - GetDot;
    if BufSChar(Goals, Distance) then begin
      c := GetChar(GetDot);
      if c in Lparens then Level := Level - 1;
      if c in Rparens then Level := Level + 1;
      if c in Quotes then begin
	Distance := WTop - GetDot;
	if not BufSChar([c], Distance) then goto 9;
      end;
    end
    else goto 9;
  end;
  lp := GetChar(GetDot);
  if lp = '(' then rp := ')';
  if lp = '[' then rp := ']';
  if lp = '<' then rp := '>';
  if lp = '{' then rp := '}';
 (*@VMS: if lp = chr(171) then rp := chr(187); *)
  if rp <> GetChar(Start-1) then TrmBeep;
  WinUpDate;			(* Show the matching left paren... *)
  BVoid := Check(1);		(* ... for a second *)
  9:
  SetDot(Start);		(* Restore everyting *)
end;

(*---------------------------------------------------------------------------*)

procedure GetString(var Line: string; Start, Stop: bufpos);
var
  p: bufpos;
  i: integer;
begin
  Line := '                                        ';
  i := 0;			(* Clear string index *)
  for p := Start to Stop do begin
    i := i + 1;			(* Bump string index *)
    if i <= StrSize		(* Range check and store character *)
    then Line [i] := GetChar(p);
  end;
end;

(*---------------------------------------------------------------------------*)
(*  This routine Selects the modes for the newly visited file.               *)

procedure GetFileOptions;
const
  SelectString = '-*-                                     ';
  SelectLength = 3;
var
  p, q: bufpos;
  Start, Stop: bufpos;
  Token: string;
  Mode: majors;
  Minor: minors;
  MajorGuess: majors;
  MinorGuess: setofminors;
begin
  MajorGuess := TrueMode;	(* Initialize the major mode guess *)
  MinorGuess := CurrName^.MinorModes; (* Initialize the minor mode guess *)
  SetDot(0);			(* Start searching from beginning of buffer. *)
  SetDot(BlankLines(1, true));	(* Skip blank lines, if any. *)
  if LineSearch(SelectString, SelectLength)
  then begin			(* Start of mode specification found *)
    Start := GetDot;		(* Get position after -*- *)
    if LineSearch(SelectString, SelectLength)
    then begin			(* End of mode specification found *)
      Stop := GetDot - SelectLength;
      while SpaceOrTab(GetNull(Start))
      do Start := Start + 1;	(* Skip spaces forward ... *)
      repeat			(* ... and backward *)
	Stop := Stop - 1;
      until not SpaceOrTab(GetNull(Stop));
      p := Start;		(* Copy starting position *)
      while p < Stop do begin	(* As long as there is more to handle... *)
	q := p;
	while not SpaceOrTab(GetChar(q)) and (q < Stop)
	do q := q + 1;		(* Find the end of a word here. *)
	GetString(Token, p, q);	(* Pick up next mode specifier *)
	for Mode := succ(FirstMajor) to pred(LastMajor)
	do begin
	  if StrCompare(MajorName [Mode], Token) = 0
	  then MajorGuess := Mode;
	end;
	for Minor := succ(FirstMinor) to pred(LastMinor)
	do begin
	  if StrCompare(MinorName [Minor], Token) = 0
	  then MinorGuess := MinorGuess + [Minor];
	end;
	p := q;
	while SpaceOrTab(GetNull(p)) do p := p + 1;
      end; (* while loop over mode spec *)
    end; (* Second -*- found *)
  end; (* First -*- found *)
  SetMajor(MajorGuess);		(* Set major mode *)
  SetMinor(MinorGuess);		(* Set minor modes *)
end;

(*---------------------------------------------------------------------------*)
 
procedure WriteFile(var Name: string; Start, Stop: bufpos);
var Pos :	bufpos;		(* Text buffer position *)
    Block :	dskblock;	(* Disk buffer *)
begin
  DiskCheck(DskOpen(Name, 'W'));(* Open the file for write *)
  EchoClear;			(* Clear the echo area *)
  EchoString('Written:                                ');
  EchoUpdate;			(* Update echo area and force out *)
  Pos := Start; 		(* Initialize the disk position *)
  while Pos < Stop - DskSize do
  begin
    GetBlock(Pos, DskNext);	(* Read a disk block from the buffer *)
    DiskCheck(DskWrite(DskSize)); (* Write the block *)
    Pos := Pos + DskSize	(* Advance to the next block *)
  end;
  GetBlock(Pos, DskNext); 	(* Read the last block *)
  DiskCheck(DskWrite(Stop - Pos)); (* Write the final block *)
  DiskCheck(DskClose);		(* Close the file *)
  TrueName(Name, 'F');		(* Get the true name of the file *)
  EchoString(Name)		(* Write the file name *)
end;

(*---------------------------------------------------------------------------*)
 
procedure ReadFile(var Name: string; Visit: boolean);
var Code :	integer;	(* Disk I/O status code *)
    Count :	integer;	(* Number of characters read *)
    P :		dskbp;		(* Pointer to disk block *)
    FileType :	integer;	(* File type code *)
begin
  Code := DskOpen(Name, 'R');	(* Try to open the file *)
  if Visit and (Code = DskWarning) then  (* Visiting a new file? *)
  begin 			(* Yes *)
    EchoClear;			(* Clear the echo line *)
    EchoString('(New File)                              ');
    SetDot(0);
    Delete(GetSize)		(* Kill everything *)
  end else begin
    if Code = DskWarning then	(* If not visiting a file *)
     Code := DskFatal;		(* File not found is fatal *)
    DiskCheck(Code);		(* Check for errors *)
    if Visit then		(* Visiting? *)
    begin
      SetDot(0);		(* Goto beginning of buffer *)
      Delete(GetSize)		(* Kill everything *)
    end;
    Count := DskRead(P);	(* Read a disk block *)
    while Count >= 0 do
    begin			(* Loop 'till end of file *)
      InsBlock(P, Count);	(* Insert the data *)
      Count := DskRead(P)	(* Read the next block *)
    end;
    DiskCheck(Count);		(* Check for errors *)
    DiskCheck(DskClose) 	(* Close the disk *)
  end;
  TrueName(Name, 'F');		(* Get the true name of the file *)
  if Visit			(* Visiting a new file? *)
  then GetFileOptions;		(* Set modes *)
end;

(*---------------------------------------------------------------------------*)

procedure ArgWrite;
begin
  EchoClear;
  EchoString('ARG:                                    ');
  if ArgDigits then
    EchoDec(ArgArg*ArgSign)
  else if ArgSign < 0 then
    EchoWrite('-');
  EchoWrite(' ')
end;

(*---------------------------------------------------------------------------*)

procedure CheckArg(I: integer);
begin
  if I >= (MaxInt - 10) div 10 then
    Error('ATL? Argument Too Large                 ')
end;

(*---------------------------------------------------------------------------*)

procedure KillCheck;
begin
  if FuncCount-1 <> KillIndex then	(* Last command wasn't a kill? *)
    KillPush;			(* No, flush kill buffer *)
  KillIndex := FuncCount	(* Remember this is last kill *)
end;

(*---------------------------------------------------------------------------*)

(*  Be smarter, use NInsert twice... *)

procedure TabTo(Column: integer);
begin				(* Tab to a given column *)
  while UsingTabs and (HorPos <  8 * (Column div 8)) do
    Insert(Chr(HorizontalTab));	(* Insert tabs *)
  while HorPos < Column do
    Insert(' ')			(* Insert spaces *)
end;

(*---------------------------------------------------------------------------*)
(*  This routine implemens the function "Center Line".                       *)

procedure CentLines(count: integer);
var
  i: integer;
begin
  SetDot(GetLine(0));
  for count := 1 to count do begin
    DelHorSpace(0);
    SetDot(EndLine);
    DelHorSpace(0);
    i := (FillColumn - HorPos) div 2;
    SetDot(GetLine(0));
    TabTo(i);
    SetDot(GetLine(1));
  end;
end;

(*---------------------------------------------------------------------------*)
(*  This routine implements the function "Find File".                        *)

procedure FindFile;
var
  Test, Match: refname;
  Code: integer;
  FileName: string;
  TrueFileName: string;
  BufferName: string;
begin
  EchoClear;
  ReadFName('Find File:                              ', FileName, Ivoid);
  EchoClear;
  EchoUpdate;
  Code := DskOpen(FileName, 'R');
  DiskCheck(Code);
  if Code <> DskWarning then begin
    IVoid := DskClose;
    TrueName(TrueFileName, 'F');
    TrueName(BufferName, 'B');
  end else begin
    TrueFileName := FileName;
    TrueName(BufferName, 'B');
  end;
  Test := ZeroName^.Right;
  Match := nil;
  while (Match = nil) and (Test <> ZeroName) do begin
    if Test^.FileName = TrueFileName
    then Match := Test
    else Test := Test^.Right;
  end;
  if Match <> nil
  then SelBuffer(Match)
  else begin
    SelBuffer(CreBuffer(BufferName));
    ReadFile(FileName, true);
    SetDot(0);
    SetModified(false);
    CurrName^.FileName := TrueFileName;
    CurrName^.NoFileName := false;
    (* PosKludge; *)
  end;
  ModeChanged := true;
end;

(*---------------------------------------------------------------------------*)

procedure MakeNewLines(HowMany: integer);
var
  i: integer;
begin
  for i := 1 to HowMany do
  begin
    if (GetLine(3) - GetLine(2) > 0)
    and (GetLine(3) - GetDot = 3 * EOLSize)
    then SetDot(GetLine(1))
    else InsEOL;
  end
end;

(*---------------------------------------------------------------------------*)

procedure DownLine(Argument: integer);
var
  p: bufpos;
begin
  if DownIndex <> FuncCount -1 then DotPos(IVoid, GoalColumn);
  if Argument < 0 then
    SetDot(GetLine(Argument))
  else if Argument = 1 then
  begin
    P := EndLine;
    SetDot(GetLine(1));
    if P = GetDot then		(* No more lines? *)
      if KbdRunning		(* No more lines.  Running a macro? *)
      then BVoid := KbdStop	(* Yes, halt it softly. *)
      else InsEOL;		(* No, insert an end-of-line sequense. *)
  end
  else
    SetDot(GetLine(Argument));
  SetDot(PosDot(GoalColumn))
end;

(*---------------------------------------------------------------------------*)

procedure IndForComment;
label 8;
var
  i, BLen, ELen: integer;
begin
  BLen := CBeginLength[MajorMode];
  ELen := CEndLength[MajorMode];
  SetDot(GetLine(0));		(* Go to beginning of line *)
  if LineSearch(CBeginString[MajorMode], BLen)
  then begin
    SetDot(GetDot - BLen);	(* Now we are just before the comment start *)
    if HorPos = 0		(* If comment starts at left margin... *)
    then goto 8			(* ...don't move comment *)
  end else begin
    SetDot(EndLine);
    for i := 1 to BLen do Insert(CBeginString[MajorMode, i]);
    for i := 1 to ELen do Insert(CEndString[MajorMode, i]);
    SetDot(GetDot - BLen - ELen)
  end;
  DelHorSpace(-1);		(* Strip trailing blanks *)
  i := CommColumn[MajorMode];	(* Get desired pos *)
  if HorPos >= i then i := HorPos + 1;
  TabTo(i);			(* Tab to the comment column *)
8:
  SetDot(GetDot + BLen);	(* Restore position *)
end;

(*---------------------------------------------------------------------------*)

procedure DownCommentLine(Argument: integer);
var
  p: bufpos;
  BLen, ELen: integer;
begin
  BLen := CBeginLength[MajorMode];
  ELen := CEndLength[MajorMode];
  P := EndLine;
  while SpaceOrTab(GetNull(P-1)) do P := P - 1;	(* Skip trailing blanks *)
  P := P - BLen - ELen;		(* Point to possible comment start *)
  if P >= GetLine(0) then	(* If there is room for a comment.. *)
  begin
    SetDot(P);			(* Set dot to the possible comment *)
    if LineSearch(CBeginString[MajorMode], BLen)
    then begin			(* Now we stand after Comment Start: *)
      P := GetDot - BLen;	(* Adjust P in case of unterminated comment *)
      SetDot(EndLine);		(* Go to end of line *)
      Delete(P - GetDot);	(* Delete the Comment Start *)
      DelHorSpace(0)		(* Strip off trailing blanks *)
    end
  end;
  DownLine(Argument);
  IndForComment
end;

(*---------------------------------------------------------------------------*)

function RegLines(P, Q: integer): integer;
var R, T: bufpos;
    I: integer;
begin					(* Counts the number of WHOLE lines *)
  I := -2;				(* in the region /RV *)
  R := GetDot;				(* Save where we are *)
  T := GetSize;				(* Not past here *)
  repeat
    SetDot(P);				(* Go to next line *)
    P := GetLine(1);
    I := I + 1;				(* increment counter *)
  until (P = T) or (P > Q);		(* Stop when we pass end or buffer *)
  if P = T then I := I + 1;		(* Ugly but necessary *)
  SetDot(R);				(* Back to where we were.. *)
  RegLines := I			(* and return result *)
end;

(*---------------------------------------------------------------------------*)

procedure IndentLine(I: integer);	(* Indent the line to horpos i /RV *)
begin
  SetDot(GetLine(0));			(* To the start of the line, delete *)
  while SpaceOrTab(GetNull(GetDot)) do Delete(1);	(*  any indentation *)
  if GetDot <> EndLine			(* If there is more then... *)
    then TabTo(I);			(* put in the new indentation *)
end;

(*---------------------------------------------------------------------------*)

function BreakLine: boolean;		(* Breaks the line if too long /RV *)
var P, Q :bufpos;
    I: integer;
begin
  BreakLine := false;			(* Assume not broken *)
  if HorPos > FillColumn		(* If we need to break the line *)
    then
      begin
	P := GetDot; Q := P;		(* Save old dot *)
	repeat				(* Scan for the beginning of *)
	  Q := Q - 1			(* the last word *)
	until (Q = 0) or (SpaceOrTab(GetNull(Q-1)));
	if Q > GetLine(0) + FillPLength	(* If the last word was not *)
	  then			(* also the first *)
	    begin
	      SetDot(Q);	(* Position dot between the words *)
	      while SpaceOrTab(GetNull(GetDot-1)) do Delete(-1);
	      InsEOL;
	      for I := 1 to FillPLength do (* Insert fillprefix *)
	        Insert(FillPrefix[I]);
	      SetDot(GetDot + Blank(1)); (* Reposition dot *)
	      BreakLine := true
	    end
      end
end;

(*---------------------------------------------------------------------------*)

procedure JoinLines(Dir: integer);	(* Joins lines forwards or... *)
var P: bufpos;				(* backwards /RV *)
begin
  if Dir<0
    then
      begin				(* Joining backwards *)
	P := GetLine(0);		(* Get start of line *)
	SetDot(P);			(* Go to it *)
	if P>0 then Delete(- EOLSize)	(* If not at start delete line end *)
      end
    else
      begin				(* Joining forwards *)
	P := EndLine;			(* Get end of line *)
	SetDot(P);			(* Go to it *)
	if P<GetSize then Delete(EOLSize)(* If not at end delete line end *)
      end;
  DelHorSpace(0);			(* Delete excess blanks *)
  Insert(' ')				(* insert just one *)
end;

(*---------------------------------------------------------------------------*)

procedure LineFill(Justify: boolean);	(* Fills one line /RV *)
var P: bufpos;
    B: boolean;

  procedure JustifyLine;		(* Justifies one line to right *)
  label 9;				(* margin of fillcolumn /RV *)
  var WBlanks, Puncs, ToFill,
      ExSpace, NormSpace, I, J: integer;
      P, Q: bufpos;
  begin
    WBlanks := 0; Puncs := 0;	(* At start of line *)
    Q := EndLine;		(* End of the line *)
    SetDot(GetDot + Blank(1));	(* To the end of next word *)
    P := GetDot;
    while P < Q do			(* If not at end of line *)
      begin
	if GetNull(P-1) in ['!',',','.',':',';','?']
	  then Puncs := Puncs + 1;	(* Increment counters *)
	WBlanks := WBlanks + 1;
	SetDot(P + Blank(1));	(* And go to next end of word *)
	P := GetDot
      end;
    if WBlanks = 0 then goto 9;		(* Can't justify only one word *)
    ToFill := FillColumn - HorPos;	(* How many fillers do we need *)
    if ToFill < Puncs				(* If more end punctuation *)
      then					(* than necessary fills *)
	begin Puncs := ToFill; ToFill := 0	(* then have just them *)
	end
      else
	ToFill := ToFill - Puncs;		(* or subtract them *)
    NormSpace := ToFill div WBlanks;	(* The number of normal inserts *)
    ExSpace := ToFill mod WBlanks;	(* and the extra ones needed *)
    SetDot(GetLine(0));			(* Start at the beginning *)
    for I := 1 to WBlanks do		(* Pass through all the blanks *)
      begin
	SetDot(GetDot + Blank(1));
	if (GetNull(GetDot-1) in ['!',',','.',':',';','?']) and (Puncs > 0)
	  then						(* If punctuation, *)
	    begin Insert(' '); Puncs := Puncs - 1	(* insert space and *)
	    end;					(* decrement counter *)
	if I <= ExSpace then Insert(' ');	(* Add extra space *)
	for J := 1 to NormSpace do Insert(' ');	(* and normal spaces *)
      end;
  9:
  end;		(* End of justifyline *)

begin
  repeat
    SetDot(GetDot + Blank(1));	(* To end of next word *)
    while SpaceOrTab(GetNull(GetDot)) do
      Delete(1);			(* Delete blanks *)
    Insert(' ');			(* Insert one space *)
    SetDot(GetDot-1);			(* We must be at the end of the word *)
    B := BreakLine;			(* Break the line ? *)
    if B and Justify			(* If broken and we are to justify *)
      then
	begin
	  P := GetDot - GetLine(0);	(* then save where we are in line, *)
	  SetDot(GetLine(-1));		(* justify previous line *)
	  JustifyLine;
	  SetDot(GetLine(1) + P)	(* and back to where we were *)
	end;
    SetDot(GetDot+1);			(* Back to where we were *)
  until GetDot = EndLine;		(* Repeat until we reach end of line *)
  Delete(-1)				(* Delete the extra space there *)
end;

(*---------------------------------------------------------------------------*)

function GtLineType: linetype;		(* Returns the type present line /RV *)
label 9;				(* Like EMACS (almost) *)
var P: bufpos;
    I: integer;
begin
  P := GetLine(0);
  if P = EndLine
    then
      begin GtLineType := BlLine; goto 9	(* Blank line is type blline *)
      end;
  if GetNull(P) = Chr(12)
    then
      begin GtLineType := BpLine; goto 9	(* Pagemark then type bpline *)
      end;
  if MajorMode = TextMode
    then
      begin					(* Oh no! we're in TEXT mode *)
	GtLineType := BpLine;			(* Now we test for bpline *)
	for I := 1 to FillPLength do
	  if GetNull(P+I-1) <> FillPrefix[I]	(* If fillprefix does not *)
	    then goto 9;			(* start line, then bpline *)
	if GetNull(P+FillPLength) <= ' '	(* If character after prefix *)
	  then goto 9;				(* blank or control, bpline *)
      end;
  GtLineType := ParLine;			(* Or we're in a paragraph *)
9:
end;

(*---------------------------------------------------------------------------*)

function Paragraphs(D: integer): integer;	(* Skips forwards or *)
label 9;				(* backwards paragraphs /RV *)
var I: integer;
    P, Q: bufpos;
begin
  P := GetDot; Q := GetSize;		(* Various limits *)
  for I := 1 to D do			(* To go forwards *)
    begin
      while (GetDot < Q) and		(* Pass over blanklines *)
	    (GtLineType = BlLine) do SetDot(GetLine(1));
      if GetDot = Q then goto 9;	(* Exit if at end *)
      SetDot(GetLine(1));		(* Into paragraph *)
      while (GetDot < Q) and		(* Pass over paragraphlines *)
	    (GtLineType = ParLine) do SetDot(GetLine(1));
      if GetDot = Q then goto 9;	(* Exit if at end *)
    end;
  for I := 1 to -D do			(* To go backwards *)
    begin
      if GetDot = GetLine(0)		(* We must go at least one line *)
	then SetDot(GetLine(-1))
	else SetDot(GetLine(0));
      while (GetDot > 0) and		(* Pass over blanklines *)
	    (GtLineType = BlLine) do SetDot(GetLine(-1));
      if GetDot = 0 then goto 9;	(* Exit if at beginning *)
      while (GetDot > 0) and		(* Pass over paragraphlines *)
	    (GtLineType = ParLine) do SetDot(GetLine(-1));
      if GetDot = 0 then goto 9;	(* Exit if at beginning *)
      if GtLineType = BlLine
	then SetDot(GetLine(1));	(* Into paragraph *)
    end;
9:
  Paragraphs := GetDot - P;		(* Return displacement *)
  SetDot(P)				(* Back to where we were *)
end;

(*---------------------------------------------------------------------------*)

procedure RegionFill(Justify: boolean);	(* Fill a region /RV *)
var PrevLine, PresLine: linetype;
    Start, Stop, P:bufpos;
    I ,J ,NumLines: integer;
begin
  GetRegion(Start, Stop);
  NumLines := RegLines(Start, Stop) + 1;	(* Number of lines *)
  SetDot(Stop);
  if Stop <> GetLine(0)			(* Last line in region? *)
    then NumLines := NumLines + 1;
  SetDot(Start);
  Start := GetLine(0);			(* We start at the beginning of *)
  SetDot(Start);			(* the line *)
  PrevLine := BlLine;			(* Do not link with previous line *)
  for I := 1 to NumLines do		(* Loop through the lines *)
    begin
      PresLine := GtLineType;
      case PresLine of
	BlLine: ;			(* Present line blank, do nothing *)
	BpLine:				(* Present line paragraph beginning? *)
	    LineFill(Justify);		(* Just fill it *)
	ParLine:			(* We are in a paragraph *)
	  begin
	    if PrevLine = BlLine
	      then				(* Do not join to blank line *)
		begin				(* but reindent this one *)
		  while SpaceOrTab(GetNull(GetDot)) do
		    Delete(1);
		  for J := 1 to FillPLength do
		    Insert(FillPrefix[J])
		end
	      else
		JoinLines(-1);		(* Join to other types *)
	    LineFill(Justify);		(* Just fill it *)
	  end;
      end;	 (* End of case *)
      PrevLine := PresLine;		(* Now the previous line *)
      SetDot(GetLine(1))		(* Next line *)
    end;				(* End of loop *)
  SetMark(GetDot);			(* Reset mark *)
  SetDot(Start)				(* Return to start *)
end;

(*---------------------------------------------------------------------------*)

function Pages(D: integer): integer;	(* Skip over pages /RV *)
label 9;
var I: integer;
    P, Q: bufpos;
begin
  P := GetDot; Q := P;
  for I := 1 to D do			(* Forwards to next page *)
    repeat				(* Find a formfeed *)
      while not((GetNull(P) = Chr(0)) or (GetNull(P) = Chr(12))) do P := P + 1;
      if P < GetSize
	then P := P + 1
	else goto 9;			(* Exit if end of buffer *)
      SetDot(P);
    until P = GetLine(0) + 1;		(* Is it at beginning of line? *)
  for I := 1 to -D do			(* Backwards to next page mark *)
    repeat
      if P > 0
	then P := P - 1			(* Back one character *)
	else goto 9;
      while (P > 0) and (GetNull(P-1) <> Chr(12)) do P := P-1;
      SetDot(P)				(* Find a formfeed *)
    until (P = 0) or (P = GetLine(0) + 1);	(* At beginning of line? *)
9:
  Pages := P - Q;			(* Return displacement *)
  SetDot(Q)
end;

(*---------------------------------------------------------------------------*)

procedure PosKludge;
var
  PageNumber, LineNumber, CharNumber: integer;
begin
  TruePos(PageNumber, LineNumber, CharNumber);
  if PageNumber > 1 then SetDot(GetDot + Pages(PageNumber - 1));
  if LineNumber > 1 then SetDot(GetLine(LineNumber - 1));
  if GetDot + CharNumber > GetSize
  then SetDot(GetSize)
  else SetDot(GetDot + CharNumber);
end;

(*---------------------------------------------------------------------------*)

function List(D: integer): integer;	(* This function passes over lists *)
var P ,Q , R: bufpos;
    I: integer;
begin
  P := GetDot;
  R := P;				(* Save starting point *)
  Q := GetSize;
  for I := 1 to D do
    begin				(* Skip to interesting character *)
      while (P < Q) and not(GetNull(P) in ['(',')']) do P := P + 1;
      if GetNull(P) = '('		(* If it was a list beginning *)
        then
	  repeat			(* Then go to the end *)
	    P := P + 1;
	    if GetNull(P) = '('		(* Have we found another list *)
	      then			(* Then pass over it *)
	        begin SetDot(P); P := P + List(1);
		end;
	  until (P >= Q) or (GetNull(P) = ')');	(* Have we reached the end? *)
      if P >= Q					(* Of the buffer as well? *)
	then
	  begin SetDot(Q); Error('                                        ')
	  end;
      P := P + 1
    end;
  for I := 1 to -D do
    begin				(* Skip to interesting character *)
      while (P >= 0) and not(GetNull(P-1) in ['(',')']) do P := P - 1;
      if GetNull(P-1) = ')'		(* If it was a list end *)
        then
	  repeat			(* Then go to the beginning *)
	    P := P - 1;
	    if GetNull(P-1) = ')'	(* Have we found another list *)
	      then			(* Then pass over it *)
	        begin SetDot(P); P := P + List(-1);
		end;
	  until (P<=0) or (GetNull(P-1) = '(');	(* Have we reached the end? *)
      if P <= 0					(* Of the buffer as well? *)
	then
	  begin SetDot(0); Error('                                        ')
	  end;
      P := P - 1;
    end;
  SetDot(R);
  List := P - R
end;

(*---------------------------------------------------------------------------*)

procedure NameChar(var S: string; Index: integer);
var Pos: integer;

  procedure Put(Ch: char);
  begin (*Put*)
    if Pos <= 40 then begin
      Pos := Pos + 1; S[Pos] := Ch
    end;
  end; (*Put*)

  procedure Append(Source: string); (* Add the non-blank part to S *)
  var I: integer;
  begin (*Append*)
    for I := 1 to StrLength(Source) do
    Put(Source[I])
  end; (*Append*)

begin (*NameChar*)
  S := '                                        ';
  Pos := 0;
  if Index >= 512 then begin
    Append('Control-                                ');
    Index := Index - 512;
  end;
  if Index >= 256 then begin
    Append('Meta-                                   ');
    Index := Index - 256;
  end;
  if Index = Rubout
  then Append('Rubout                                  ')
  else if Index > ord(' ')
  then Put(Chr(Index))
  else if Index = Ord(' ')
  then Append('Space                                   ')
  else if Index = BackSpace
  then Append('Backspace                               ')
  else if Index = HorizontalTab
  then Append('Tab                                     ')
  else if Index = LineFeed
  then Append('Linefeed                                ')
  else if Index = CarriageReturn
  then Append('Return                                  ')
  else if Index = Escape
  then Append('Escape                                  ')
  else begin
    Put('^'); Put(Chr(Index+64))
  end
end; (*NameChar*)

(*---------------------------------------------------------------------------*)

procedure listhelp;
begin
  if RecLevel <= 1
  then begin
    OvWString('You are at top level.                   ');
    OvWLine
  end else begin
    OvWString('You are in a recursive editing level    ');
    OvWString('inside                                  ');
    OvWString(RecName);
    OvWLine;
    OvWString('To abort the command, type C-].  To     ');
    OvWString('proceed with it, type C-M-Z.            ');
    OvWLine;
(*
!    OvWString('For more information about this command,');
!    OvWString('use Help option R.                      ');
!    OvWLine;
*)
    OvWLine
  end;
  OvWString('Type a Help option to say which kind of ');
  OvWString('help you want:                          ');
  OvWLine;
  OvWString('A   lists all the functions Apropos a   ');
  OvWString('keyword.   You type the keyword.        ');
  OvWLine;
  OvWString('B   lists basic help about AMIS.        ');
  OvWLine;
  OvWString('C   says what a certain Command         ');
  OvWString('(character) does.   You type the        ');
  OvWString('character.                              ');
  OvWLine;
  OvWString('D   describes a function.   You type    ');
  OvWString('the name.                               ');
  OvWLine;
  OvWString('N   views a file of AMIS news.          ');
  OvWLine;
(*
!  OvWString('R   describes current Recursive editing ');
!  OvWString('level.                                  ');
!  OvWLine;
*)
  OvWString('W   run Where is.                       ');
  OvWLine;
  OvWString('Q or Rubout  Quits -- you don''t really  ');
  OvWString('want help.                              ');
  OvWLine;
  OvWLine;
  OvWString('For a basic introduction to AMIS, run   ');
  OvWString('the program ATEACH.                     ');
  OvWLine;
  OvWLine
end;

(*---------------------------------------------------------------------------*)

procedure viewfile(filename: string);
var	i,j	: integer;
	p	: dskbp;
	line	: string;
begin
  i := dskopen(filename, 'R');
  if i <> 0			(* If any error occurred.. *)
  then diskcheck(DskFatal);	(* Treat as hard error *)
  TrueName(line, 'F');		(* Get the full file name. *)
  modeclear;
  modestring('Viewing file                            ');
  Modestring(line);
  echoclear;
  WinOvTop;
  i := dskread(p);		(* Read a block from the file *)
  while i >= 0 do begin
    for j := 1 to i do winoverwrite(p^[j]); (* Output the file *)
    i := dskread(p)		(* Read another block *)
  end;
  diskcheck(i);
  diskcheck(dskclose);		(* Close the file *)
  modeline;			(* Get old mode line again *)
end;

(*---------------------------------------------------------------------------*)

(* ==> UTILITY *)

(*@VMS: [global] *)
function SubString(Main, Sub: string): boolean;
label 8, 9;
var
  Len: integer;
  FirstChar: char;
  i, j: integer;
begin
  Len := StrLength(Sub);	(* Get length of substring *)
  FirstChar := UpCase(Sub[1]);	(* Get first character *)
  SubString := false;
  for i := 1 to StrSize + 1 - Len do begin
    if UpCase(Main[i]) = FirstChar
    then begin
      for j := 2 to Len do begin
	if UpCase(Main[i+j-1]) <> UpCase(Sub[j])
	then goto 8;
      end;
      SubString := true; goto 9
    end;
    8:
  end;
  9:
end;

(*---------------------------------------------------------------------------*)

function ListKeys(Prompter: string; f: fcode): boolean;
var
  Virgin: boolean;
  i: integer;

  procedure TypeChar(Index: integer);
  var
    s: string;
  begin
    if Virgin
    then OvWString(Prompter)
    else begin
      WinOverWrite(','); WinOverWrite(' ')
    end;
    if Index >= 1024 then begin
      OvWString('Control-X                               ');
      Index := Index - 1024;
    end;
    NameChar(s, Index);
    OvWString(s);
    Virgin := false;
  end;

begin
  Virgin := true;
  for i := 0 to 1023 do
  if DispTab[i] = f
  (*@TOPS: then if not odd(i DIV 128) *)
  then TypeChar(i);
  for i := 0 to 255 do
  if CXTable[i] = f
  (*@TOPS: then if i < 128 *)
  then TypeChar(i + 1024);
  ListKeys := not Virgin;
end;

(*---------------------------------------------------------------------------*)

procedure Apropos;
var
  Line: string;
  f: fcode;
  GotMatch: boolean;
begin
  EchoClear;
  ReadLine('Apropos:                                ', Line, Ivoid);
  EchoClear;
  GotMatch := false;
  for f := succ(ffirst) to pred(flast)
  do begin
    if SubString(FuncName[f], Line)
    then begin
      GotMatch := true;
      OvWString(FuncName[f]); OvWLine;
      if ListKeys('  which can be invoked via:             ', f)
      then OvWLine;
    end; (* Substring match *)
  end; (* Loop over functions *)
  if GotMatch
  then begin
    OvWLine;
    OvWString('(Done)                                  ');
  end else begin
    OvWString('There is no match for the substring     ');
    OvWString(Line);
  end;
  OvWLine;
end;

(*---------------------------------------------------------------------------*)

procedure bhelp;		(* This procedure does the job of *)
var				(* the 'B' subcommand in helper *)
  FileName: string;
begin
  GetFSpec(FileName, 5);	(* TED:AMIS.BHL *)
  viewfile(FileName);
end;

(*---------------------------------------------------------------------------*)

procedure CHelp;		(* This procedure does the job of *)
var				(* the 'C' subcommand in helper *)
  C	: char;
  I	: integer;
  F	: fcode;
  Name	: string;

  procedure TypeFunction(F: fcode);
  begin (** TypeFunction **)
    if F = FIllegal
    then begin
      OvWString('is not used.                            ');
      OvWLine
    end
    else if (F = FMacroExtend) or (F = FMacroCharacter)
    then begin
      (***** Fix this for name of macro *****)
      OvWString('runs a user defined keybord macro.      ');
      OvWLine;
    end else begin
      OvWString('runs the function                       ');
      OvWString(FuncName[F]);
      OvWLine;
    end;
  end; (** TypeFunction **)

begin (** CHelp **)
  EchoClear;			(* Clear echo area and prompt *)
  EchoString('Character:                              ');
  EchoUpDate;			(* Force update of prompter *)
  I := ReadCmdChar;		(* Read a command character *)
  F := CaseCheck(I);		(* Get corresponding function *)
  OvWString('The character                           ');
  NameChar(Name, I);
  OvWString(Name);
  if F = FChrExtend then begin
    OvWString('is an escape-prefix for more commands.  '); OvWLine;
    OvWString('It reads a character (subcommand) and   ');
    OvWString('dispatches on it.                       '); OvWLine;
    OvWString('Type a subcommand to document:          '); OvWLine;
(*
 !   OvWString('Type a subcommand to document           ');
 !   OvWString('(or "*" for all):                       '); OvWLine;
 *)
    C := ReadC;			(* Read a character *)
    EchoArrow(C);
    EchoUpDate;
    F := CXTable[Ord(C)];	(* Get subfunction *)
    if F = FIllegal then begin
      if C in ['A'..'Z']	(* If illegal function, use the other case *)
      then f := CXTable[Ord(C)+32]
      else if c in ['a'..'z']
      then f := CXTable[Ord(C)-32];
    end;
    OvWString(Name);		(* Print first character in seq. *)
    NameChar(Name, Ord(C));	(* Get name of second char *)
    OvWString(Name);		(* Print it too *)
  end;
  TypeFunction(F);
end; (** CHelp **)

(*---------------------------------------------------------------------------*)

procedure DHelp;		(* This procedure does the job of *)
var				(* the 'D' subcommand in helper *)
  F	: fcode;
begin (** DHelp **)
  EchoClear;
  EchoString('Describe:                               ');
  EchoUpDate;
  F := ReadFunc;
  GiveDocumentation(FuncName[F])
end; (** DHelp **)

(*---------------------------------------------------------------------------*)

procedure NHelp;		(* Thie procedure does the job of *)
var				(* the 'N' subcommand in helper *)
  FileName: string;
begin
  GetFSpec(FileName, 6);	(* DOC:AMIS.NEW *)
  ViewFile(FileName);
end;

(*---------------------------------------------------------------------------*)

procedure WHelp;		(* This procedure does the job of *)
var				(* the 'W' subcommand in helper *)
  f: fcode;
begin
  EchoClear;
  EchoString('Where is:                               ');
  f := ReadFunc;
  OvWString('The function                            ');
  OvWString(FuncName[f]);
  if not ListKeys('can be invoked via                      ', f)
  then OvWString('can be invoked only with M-X            ');
  OvWLine;
end;

(*---------------------------------------------------------------------------*)

procedure Helper;		(* The main help dispatcher *)
var
  C	: char;			(* Scratch *)
  More	: boolean;
begin (** Helper **)
  More := true;
  while More do begin
    EchoString('Doc (? for help):                       ');
    EchoUpDate;			(* Force output to echo area *)
    c := upcase(readc);		(* Read a character *)
    if C = Chr(HelpChar) then C := '?';
    if C = Chr(RubOut) then C := 'Q';
    EchoArrow(c);
    EchoArrow(' ');
    echoupdate;			(* Force out echo of character *)
    More := false;		(* Assume we break the loop *)
    if c = '?' then begin	(* Help character typed? *)
      ListHelp;			(* Yes, list available help. *)
      More := true;		(* ... and keep looping. *)
    end
    else if c = 'A' then Apropos
    else if c = 'B' then BHelp
    else if c = 'C' then CHelp
    else if c = 'D' then DHelp
    else if c = 'N' then NHelp
    else if c = 'W' then WHelp
    else if c = 'Q' then WinOvClear
    else begin
      EchoClear;
      EchoArrow(c);
      EchoString(' is meaningless here.                   ');
      More := true;
    end;
  end;
end;

(*---------------------------------------------------------------------------*)

procedure SexprMagic(var Start,Elem2: bufpos; var Count,Depth: integer);

const
  Slashifier = '/';
  Nothing = 1; Atom = 2; OpenParen = 3; CloseParen = 4;

var
  Dot, LinEnd: bufpos;
  NextChar, Stop, CommChar: char;
  N, Level: integer;
  Zero, One, Two: bufpos;

  procedure Gobble;
  begin
    NextChar:=GetNull(Dot);
    Dot:=Dot+1
  end;

  function ScanToken: integer;
  begin (* ScanToken *)
    Gobble;
    while SpaceOrTab(NextChar) do	(* Eat leading spaces *)
      Gobble;
    if NextChar=')' then		(* Closing parenthesis? *)
      ScanToken:=CloseParen
    else if NextChar='(' then		(* Opening parenthesis? *)
      ScanToken:=OpenParen
    else if (NextChar='"')		(* String or vertical-bar atom? *)
	 or (NextChar='|')
    then begin				(* Yes, scan the string *)
      Stop:=NextChar;
      Gobble;
      repeat
	if NextChar=Slashifier then Gobble;
	Gobble
      until (NextChar=Stop)		(* Stop on line or string end *)
         or (Dot>=LinEnd);
      ScanToken:=Atom
    end
    else if (NextChar=CommChar)		(* Otherwise: Reached end of line? *)
	 or (Dot>LinEnd)
    then ScanToken:=Nothing
    else begin				(* No, so we scan an ordinary atom *)
      repeat
	if NextChar=Slashifier then Gobble;
	Gobble
      until (NextChar='(') or (NextChar=')') or (NextChar='"')
	 or (NextChar='|') or (NextChar='''') or (NextChar=CommChar)
	 or SpaceOrTab(NextChar) or (Dot>LinEnd);
      Dot:=Dot-1;			(* Back up past ending delimiter *)
      ScanToken:=Atom
    end
  end; (* ScanToken *)

  procedure Parse;			(* Here's the clever recursive hack *)
  var
    Pos: bufpos;			(* Ending position of current token *)
    Token: integer;			(* Syntactic class of current token *)
  begin
    Token:=ScanToken;			(* Scan one token *)
    Pos:=Dot;				(* Remember position *)
    if Token<>Nothing then begin	(* If not at end of line: *)
      if N>0 then begin			(* If parsing forward: *)
        case Token of
	  Atom: if Level=0 then N:=N-1;
	  OpenParen: Level:=Level+1;
	  CloseParen:
	    begin
	      Level:=Level-1;
	      if Level=0 then N:=N-1
	    end; (* if > *)
	end; (* case *)
	if N=0 then SetDot(Pos)
      end; (* if > *)

      Parse;				(* Now scan everything else *)

      if N<0 then begin			(* If parsing backward: *)
        case Token of
	  Atom: if Level=0 then N:=N+1;
	  OpenParen:
	    begin
	      Level:=Level-1;
	      if Level=0 then begin
		N:=N+1;
		Zero:=Pos
	      end
	    end;
	  CloseParen: Level:=Level+1;
	end; (* case *)
	if N=0 then SetDot(Pos);
	if Level=1 then begin
	  Two:=One; One:=Pos
	end
      end (* if < *)
    end (* recursive if *)
  end; (* Parse *)

begin (* SexprMagic *)
  CommChar:=CBeginString[MajorMode] [1];
  N:=Count;				(* Init variables used by Parse *)
  Level:=Depth;
  Dot:=GetDot;
  LinEnd:=EndLine;
  Zero:=0; One:=0; Two:=0;

  Parse;				(* Call clever recursive hack *)

  Count:=N;				(* Store results *)
  Depth:=Level;
  if Level>0 then SetDot(Dot-1);	(* Make things easier for DFIndSEXP *)
  if Zero<>0 then begin			(* Make things easier for DFIndLisp *)
    Start:=Zero-1;
    if Two>0 then begin
      while SpaceOrTab(GetNull(One)) do One:=One+1;
      Elem2:=One
    end
    else Elem2:=0
  end
  else Start:=0
end; (** SexprMagic **)

(*---------------------------------------------------------------------------*)

function FindMacro(i: integer): integer;
var
  mc: refcharassign;
begin
  mc := ZeroChar;
  while mc^.key <> i do begin
    mc := mc^.next;
    if mc = nil then Error('MAIN: ZeroChar list skrewed up.         ');
  end;
  FindMacro := mc^.code^.number;
end;

(*---------------------------------------------------------------------------*)
(* This procedure does the job of the function Set Key.                      *)

procedure SetKey(i: integer);
var
  f: fcode;

  procedure assign;
  var
    mc: refcharassign;
  begin
    if (i >= 0) and (i <= (1023 + 255)) then begin
      if f = FMacroExtend
      then begin
	f := FMacroCharacter;
	new(mc);
	mc^.next := ZeroChar;
	mc^.key := i;
	mc^.code := KbdRecMacro;
	ZeroChar := mc;
      end;
      if i >= 1024
      then CXTable [i - 1024] := f
      else DispTab [i] := f;
    end;
  end;

begin
  EchoClear;			(* Clear echo area, and prompt *)
  EchoString('Function:                               ');
  F := ReadFunc;		(* Read function to set somewhere *)
  if i <> NoArgument then assign
  else begin
    EchoClear;			(* Clear again *)
    EchoString('Put                                     ');
    if f = FMacroExtend
    then EchoString(KbdRecMacro^.Name)
    else EchoString(FuncName[f]);
    EchoString('on key:                                 ');
    EchoUpDate;			(* Allow updating echo area *)
    i := ReadCmdChar;		(* Read the command character *)
    if CaseCheck(i) = FChrExtend (* Flavour of C-X? *)
    then i := 1024 + ord(ReadC); (* Yes, next table. *)
    EchoString('Go ahead                                ');
    if YesOrNo then assign;
  end;
end; (* SetKey *)

(*---------------------------------------------------------------------------*)
(*   Do reassignments regarding the use of ^S/^Q.			     *)

procedure XonAssign;
begin
  if UsingXonXoff then begin
    DispTab[8] := FISearch;	(* ^H gets search. *)
    DispTab[28] := FQInsert;	(* ^BackSlash gets quoting. *)
    CxTable[83] := FSaveFile;	(* C-X S gets ^R Save File. *)
  end;
  XonXoff(UsingXonXoff);	(* Tell operating system. *)
end;

(*---------------------------------------------------------------------------*)

procedure Back2Indentation;
var
  p: bufpos;
begin
  p := GetLine(0);
  while SpaceOrTab(GetNull(p))
  do p := p + 1;
  SetDot(p)
end;

(*---------------------------------------------------------------------------*)

procedure BlockIndent(mode: majors);
const
  ENDfrogCASE   = 'END CASE                                ';
  ENDfrogLOOP   = 'END LOOP                                ';
  ENDfrogSELECT = 'END SELECT                              ';
  ANDfrogTHEN   = 'AND THEN                                ';
  ORfrogELSE    = 'OR ELSE                                 ';

var
  i: integer;
  k: keyword;
  p: bufpos;
  indent: boolean;

  function LineContains(key: string): boolean;
  var
    keylen: integer;
    start: bufpos;
  begin
    keylen := strlength(key);
    start := GetDot;
    LineContains := false;
    if LineSearch(key, keylen) then begin
      if Delim(GetNull(GetDot)) and Delim(GetNull(GetDot - KeyLen - 1))
      then LineContains := true;
    end;
    SetDot(start);
  end; (* LineContains *)

begin
  p := GetDot;
  Back2Indentation;
  if P <= GetDot then begin	(* In indentation? *)
    i := 0;
    if GetLine(0) > 0		(* First line? *)
    then begin			(* No. *)
      SetDot(GetLine(-1));	(* Visit the line above *)
      Back2Indentation;
      i := HorPos;
      indent := false;
      for k := succ(FirstKeyword) to pred(LastKeyword) do begin
	if k in Indenters[mode] then begin
	  if LineContains(KeyWName[k]) then indent := true;
	end;
      end;
      if mode = AdaMode then begin
	if indent then indent := not LineContains(ENDfrogCASE);
	if indent then indent := not LineContains(ENDfrogLOOP);
	if indent then indent := not LineContains(ENDfrogSELECT);
	if indent then indent := not LineContains(ANDfrogTHEN);
	if indent then indent := not LineContains(ORfrogELSE);
      end; (* frog hack *)
      if indent then i := i + BlockILevel;
      SetDot(GetLine(1))
    end;
    DelHorSpace(0);		(* Delete leading spacing *)
    TabTo(i)			(* Tab to column i *)
  end else begin
    SetDot(p);
    TabTo(HorPos div 8 * 8 + 8) (* Insert Tab *)
  end
end;

(*---------------------------------------------------------------------------*)
(*  This routine implements the function "Date Edit".                        *)

procedure DateEdit;		(* Does the job of Date Edit *)
const
  SelectString = '-*-                                     ';
  SelectLength = 3;
var
  Line: string;
  start: bufpos;
  pos: integer;
  OldFile: integer;
begin
  SetDot(0);			(* Goto beginning of buffer *)
  SetDot(BlankLines(1, true));	(* Skip blank lines, if any *)
  start := 0;			(* Assume here. *)
  if LineSearch(SelectString, SelectLength) then start := GetLine(1);
  SetDot(start);
  for Pos := 1 to CBeginLength [MajorMode] do
  insert(CBeginString[MajorMode, Pos]); (* Insert the comment start string *)
  if not CurrName^.NoFileName	(* If we have a file name ... *)
  then begin
    Line := CurrName^.FileName;
    OldFile := DskOpen(Line, 'R');
    TrueName(Line, 'D');
    if OldFile = 0 then IVoid := DskClose;
    InsString(Line)
  end;
  Insert(' ');
  DayTime(Line);		(* Insert time of day *)
  InsString(Line);
  InsString(', Edit by                               ');
  Insert(' ');
  UsrName(Line);		(* Put our name in there too *)
  InsString(Line);
  for Pos := 1 to CEndLength[MajorMode] do
  Insert(CEndString[MajorMode, Pos]); (* Finish up with end of comment *)
  MakeNewLines(1)		(* ...and a new line *)
end;

(*---------------------------------------------------------------------------*)
(*  This routine implements the function "List Files".                       *)

procedure ListFiles(BufFlag: boolean);
var
  line: string;
  len: integer;
begin
  EchoClear;
  ReadLine('List Files:                             ', Line, Len);
  EchoClear;
  DiskCheck(LsFOpen(Line, Len));
  if BufFlag then begin
    while LsFMore do Insert(LsFChar);
  end else begin
    while LsFMore do WinOverWrite(LsFChar);
  end;
  DiskCheck(LsFClose);
  if not BufFlag then begin
    OvWLine;
    OvWString('(Done)                                  ');
  end;
end;

(*---------------------------------------------------------------------------*)
(*  Routines to handle the personal flag vector:                             *)

procedure BufFlags(flags: string); external;
procedure TrmFlags(flags: string); external;
procedure WinFlags(flags: string); external;

procedure SetFlags(flags: string);
var c: char;
begin
  c := flags[1];                (* "Conformance" *)
  if c = 'E' then Antique := true;
  if c = 'G' then Antique := false;
  c := flags[10];		(* "Indent Tabs Mode" *)
  if c = '+' then UsingTabs := true;
  if c = '-' then UsingTabs := false;
  BufFlags(flags);
  WinFlags(flags);
  TrmFlags(flags);
end;

(*---------------------------------------------------------------------------*)
(*  This routine implements the function "Set Flags".                        *)

procedure SetBehaviour;
var
  line: string;
begin
  EchoClear;
  ReadLine('Flag vector:                            ', Line, IVoid);
  SetFlags(Line);
end;

(*---------------------------------------------------------------------------*)

procedure DoFunction(Func: fcode; Arg: integer);
var
  Argument: integer;
  i, j: integer;
  p, q: bufpos;
  OldDot: bufpos;
  b: boolean;
  c: char;
  f: fcode;
  s: string;

  procedure DFInsBuffer;	(* Does the job of Insert Buffer *)
  var
    target: refname;		(* The buffer we are going to insert. *)
    start: bufpos;		(* Start of inserted text. *)
  begin
    if Arg = NoArgument		(* No argument => ask for buffer *)
    then begin
      EchoClear;
      target := AskBuffer('Insert Buffer:                          ',
			  CurrName, false);
    end else begin
      target := NumFBuffer(arg);
    end;
    start := GetDot;
    if target <> nil then begin
      QCopy(target^.number, TempRegister);
      QG(TempRegister);
      QX(TempRegister, 0);
    end;
    SetMark(GetDot);
    SetDot(start);
  end;

  procedure DFKillBuffer;
  var
    ErrSave:	catchblock;	(* catching errors within Save File *)
    Skrynkel:	Boolean;	(* TRUE if Save File goofed *)
    Original:	refname;	(* CurrName saved here during SaveFile*)
    Victim:	refname;	(* The buffer to kill *)
  begin
    if Arg = NoArgument		(* No argument => ask for buffer *)
    then begin
      EchoClear;
      Victim := AskBuffer('Kill Buffer:                            ',
			  CurrName, false);
    end else begin
      Victim := NumFBuffer(arg);
    end;
    SetBuf(Victim^.Number);
    if GetModified then begin
      EchoClear;
      EchoString('Buffer                                  ');
      EchoString(Victim^.Name);
      EchoString('contains changes. Write them out        ');
      if YesOrNo then begin
        SetBuf(CurrName^.Number);
        Original := CurrName;       (* Remember current buffer *)
        ErrSave := Err;
        Skrynkel := catch(Err);
        if not Skrynkel then begin
          DoFunction(FSelectBuffer,Victim^.Number);
          DoFunction(FSaveFile,NoArgument);
        end; (* if not Skrynkel *)
        Err := ErrSave;
	DoFunction(FSelectBuffer,Original^.Number);
	if Skrynkel then Throw(Err);
      end;
    end;
    SetBuf(CurrName^.Number);
    if Victim = CurrName then begin
      EchoClear;
      EchoString('Killing currently selected buffer;      ');
      SelBuffer(AskBuffer('Select which other buffer:              ',
			  PrevName, true));
    end;
    if Victim = CurrName
    then error('KCB? Killing currently selected buffer  ');
    if PrevName = Victim then PrevName := CurrName;
    if OtherName = Victim then OtherName := nil;
    Victim^.Left^.Right := Victim^.Right;  (* Patch up the lists *)
    Victim^.Right^.Left := Victim^.Left;
    KillBuf(Victim^.Number);	(* Ahh... KILL IT!!! *)
    Dispose(Victim);		(* Give back storage *)
  end; (* DFKillBuffer *)

  procedure DFKbdName;		(* Does the job of Name Kbd Macro *)
  var
    line: string;
    m: refmacro;
  begin (** DFKbdName **)
    EchoClear;
    ReadLine('Function name:                          ', Line, IVoid);
    EchoClear;
    EchoUpdate;
    New(m);			(* Get a new keybord macro name block *)
    m^.Name := Line;		(* Set up the name *)
    m^.Number := KbdFreeze;	(* Save current macro *)
    m^.Next := ZeroMacro;
    ZeroMacro := m;
  end (** DFKbdName **);

  procedure DFUndo;		(* Does the job of Undo *)
  var OldDot, OldMark: bufpos;
  begin (** DFUndo**)
    if CurrName^.Number <> UndoBuffer (* was it done here? *)
    then error('NTB? Not This Buffer that was changed   ');
    EchoClear;
    EchoString('Undo last                               ');
    Echostring(FuncName[UndoFunction]);
    if YesOrNo			(* Ask him if we are to do it *)
    then begin
      QCopy(UndoRegister, TempRegister);
      AllowUndo;		(* Allow this to be undone *)
      OldDot := GetDot;		(* Get the dot *)
      OldMark := GetMark(true);	(* Get the mark *)
      Delete(OldMark - OldDot);	(* Zap the region *)
      QG(TempRegister);		(* Get the old stuff *)
      QX(TempRegister, 0);	(* Wipe temp register *)
      SetMark(OldMark);		(* Restore mark *)
      SetDot(OldDot);		(* Restore dot *)
    end;
  end; (** DFUndo**)

  procedure DFWhatCursorPos;	(* Does the job of What Cursor Position *)
  var	I, J	: integer;
  begin (** DFWhatCursorPos **)
    DotPos(J, I);		(* Get cursor position *)
    EchoClear;			(* Clear the echo line *)
    EchoWrite('X'); EchoWrite('=');
    EchoDec(I);			(* Write the X coordinate *)
    EchoWrite(' ');
    EchoWrite('Y'); EchoWrite('=');
    EchoDec(J);			(* Write the Y coordinate *)
    EchoWrite(' ');
    EchoWrite('C'); EchoWrite('H'); EchoWrite('=');
    EchoOct(Ord(GetNull(GetDot)));	(* Write the character after dot *)
    EchoWrite(' ');
    EchoWrite('.'); EchoWrite('=');
    EchoDec(GetDot);		(* Write dot *)
    EchoWrite('(');
    I := 0;
    if GetSize > 0
    then I :=  100 * GetDot div GetSize;
    EchoDec(I);			(* Write dot in percent *)
    EchoString('% of                                    ');
    EchoDec(GetSize);		(* Write total size *)
    EchoWrite(')');
    EchoWrite(' ')
  end; (** DFWhatCursorPos **)

  procedure DFWhatPage;		(* Does the job of What Page *)
  var	Page	: integer;
	HowFar,OldDot: bufpos;
	More	: boolean;
	Line	: string;
  begin (** DFWhatPage *)
    OldDot := GetDot;		(* Save dot *)
    SetDot(0);
    Page := 0;			(* Start at page zero *)
    Line[1] := Chr(FormFeed);
    repeat
      Page := Page + 1;		(* Bump page # *)
      HowFar := OldDot - GetDot;
      More := HowFar > 0;
      if More then More := BufSearch(Line,1,1,HowFar);
    until not More;
    SetDot(OldDot);		(* Restore dot *)
    EchoClear;
(*** EchoMsg ***)
    EchoString('Page                                    ');
  (** 'Page # Line #' **)
    EchoDec(Page);
  end; (** DFWhatPage *)

  procedure DFWriteFile;	(* Does the job of Write File *)
  var	Line	: string;
  begin (** DFWriteFile **)
    EchoClear;
    ReadFName('Write File:                             ', Line, IVoid);
    WriteFile(Line, 0, GetSize);(* Write the file *)
    SetModified(false);		(* Reset modification flag *)
    CurrName^.FileName := Line;
    CurrName^.NoFileName := false;
    ModeChanged := true		(* The mode line may have changed *)
  end; (** DFWriteFile **)

  procedure DFWriteRegion;	(* Does the job of Write Region *)
  var	Line	: string;
	First, Last: bufpos;
  begin (** DFWriteRegion **)
    EchoClear;
    ReadFName('Write Region to File:                   ', Line, IVoid);
    GetRegion(First, Last);	(* Get bounds of region *)
    WriteFile(Line, First, Last)(* Write the region into the file *)
  end; (** DFWriteRegion **)

  procedure DFIndLisp;		(* Does the job of ^R Indent for LISP *)
  label 1;
  const
    StrLAMBDA = 'LAMBDA                                  ';
    StrDEF    = 'DEF                                     ';
    StrLET    = 'LET                                     ';

  var
    Dot, IDot, Start, Elem2: bufpos;
    I, Count, Depth: integer;
    CommChar: char;

  begin (** DFIndLisp **)
    CommChar:=CBeginString[MajorMode] [1];
    Dot := GetLine(0);
    SetDot(Dot);
    IDot:=Dot;
    Count:=-1;
    Depth:=1;
    1: (* loop begin *)
      SetDot(GetLine(0));		(* Go to beginning of this line *)
      if GetDot>0 then			(* Is there a line above? *)
      begin
	SetDot(GetLine(-1));		(* Yes, up to previous line *)
	SexprMagic(Start,Elem2,Count,Depth); (* Wave magic wand *)
	if Count=0 then begin		(* At beginning of list? *)
	  SetDot(Start+1);
	  if BufSearch(StrLAMBDA, 6, 1, 6) then IDot:=Start+2
	  else if BufSearch(StrDEF, 3, 1, 3) then IDot:=Start+2
	  else if BufSearch(StrLET, 3, 1, 3) then IDot:=Start+2
	  (* We should check for DO also, but that one is more hairy *)
	  else if Elem2>0 then IDot:=Elem2
	  else IDot:=Start+1
	end
	else if Depth=1 then begin	(* Same nesting level? *)
	  Back2Indentation;	(* Yes, go to indentation *)
	  if AtEOL(GetDot,1)		(* Loop if the line was empty *)
	     or (GetNull(GetDot)=CommChar)
	     then goto 1;
	  IDot:=GetDot			(* Otherwise, use this indentation *)
	end
	else goto 1;			(* Deeper nesting, loop *)
      end;
    (* end loop *)
    SetDot(IDot);
    I:=HorPos;
    SetDot(Dot);
    DelHorSpace(0);			(* Delete leading spacing *)
    TabTo(I)				(* Tab to column i *)
  end; (** DFIndLisp **)

  procedure DFIndSEXP;		(* Does the job of ^R Indent SEXP *)
  var
    Dot, Dummy: bufpos;
    Count, Depth: integer;
    CommChar: char;
    IndComm: Boolean;
  begin
    Dot:=GetDot;
    CommChar:=CBeginString[MajorMode] [1];
    Count:=1;
    Depth:=0;
    SexprMagic(Dummy,Dummy,Count,Depth);    (* Enter S-expr with this call *)
    if Depth>0 then
      if GetNull(GetDot)=CommChar then	    (* A comment on this line? *)
        DoFunction(FIndForComm, NoArgument);
    while Depth>0 do begin
      SetDot(GetLine(1));		    (* Proceed to next line *)
      if GetDot>=GetSize then		    (* Reached buffer end to early? *)
	error('UBP? Unbalanced Parentheses in S-expr   ');
      SexprMagic(Dummy,Dummy,Count,Depth);  (* Do some scanning inside *)
      IndComm:=false;
      if Depth>0 then
	if GetNull(GetDot)=CommChar then    (* A comment on this line? *)
	  IndComm:=true;
      DoFunction(FIndForLisp, NoArgument);  (* Indent this line *)
      if IndComm then			    (* Indent comment if it exists *)
	DoFunction(FIndForComm, NoArgument);
    end; (* while *)
    SetDot(Dot)				    (* Back to where we started *)
  end; (** DFIndSEXP **)

  procedure DFTrnLines;		(* Does the job of ^R Transpose Lines *)
  var	FirstStart, FirstEnd, SecondStart, SecondEnd: bufpos;
  begin (** DFTrnLines **)
    SetDot(GetLine(0));		(* Go to beginning of line *)
    FirstStart := GetLine(-1);	(* Get start of previous line *)
    FirstEnd := GetDot;
    SecondStart := GetDot;
    SecondEnd := GetLine(1);	(* Get end of this line *)
    SwapRegions(FirstStart, FirstEnd, SecondStart, SecondEnd);
    SetDot(SecondEnd)		(* Set dot afterwards *)
  end; (** DFTrnLines **)

  procedure DFTrnRegions;	(* Does the job of ^R Transpose Regions *)
  var M: array [1..4] of bufpos;
      P: array [1..4] of integer;
      I, J, Temp: integer;
  begin (** DFTrnRegions **)
    M[1] := GetMark(true); M[2] := GetMark(true);
    M[3] := GetMark(true); M[4] := GetDot;
    P[1] := 1;  P[2] := 2;  P[3] := 3;  P[4] := 4;
    for I := 1 to 4 do begin
      for J := I+1 to 4 do begin
	if M[P[I]] > M[P[J]]
	then begin
	  Temp := P[J];  P[J] := P[I];  P[I] := Temp;
	end;
      end;
    end;
    SwapRegions(M[P[1]], M[P[2]], M[P[3]], M[P[4]]);
    Temp := M[P[2]] + M[P[3]] - M[P[1]] - M[P[4]];
    M[P[2]] := M[P[2]] - Temp;	(* Align something... *)
    M[P[3]] := M[P[3]] - Temp;
    SetDot(M[4]);
    SetMark(M[3]);
    SetMark(M[2]);
    SetMark(M[1]);
  end; (** DFTrnRegions **)

  procedure DFTrnWords;		(* Does the job of ^R Transpose Words *)
  var	M1, M2, M3, M4: integer;
  begin (** DFTrnWords **)
    M4 := GetDot + Words(1);	(* Go to end of word 2 *)
    SetDot(M4);		
    M3 := M4 + Words(-1);	(* Back over it *)
    SetDot(M3);
    M1 := M3 + Words(-1);	(* Back over word 1 *)
    SetDot(M1);
    M2 := M1 + Words(1);	(* and go to the end of first word *)
    SwapRegions(M1, M2, M3, M4);(* Exchange the words *)
    SetDot(M4)			(* Finally, set dot at end of second word *)
  end; (** DFTrnWords **)

  procedure DFReadFile(Visit: Boolean);	(* Reads or Visits a file *)
  var
    Line: string;
  begin (** DFReadFile **)
    EchoClear;
    if Visit
    then ReadFName('Visit File:                             ', Line, IVoid)
    else ReadFName('Read File:                              ', Line, IVoid);
    EchoClear;
    EchoUpdate;
    if GetModified then begin
      EchoClear;
      EchoString('Buffer                                  ');
      EchoString(CurrName^.Name);
      EchoString('contains changes.  Write them out       ');
      if YesOrNo then DoFunction(FSaveFile, NoArgument);
    end;
    ReadFile(Line, true);	(* Read in the new file into the buffer *)
    SetModified(false);		(* This buffer has never been modified *)
    SetDot(0);			(* Move to the start of the file *)
    CurrName^.FileName := Line;
    CurrName^.NoFileName := false;
    CurrName^.ReadOnly := not Visit;
    ModeChanged := true;	(* The mode line may have changed *)
    PosKludge;			(* Handle /Char and friends... *)
  end;

  procedure EndCheck;		(* Backs off indentation on end-class    *)
  var				(* token found first in a line, 	 *)
    OldDot, IStart: bufpos;	(* equiindented with the preceding line	 *)
    ExDentLine	  : boolean;
    I, IBuf, Index: integer;
    C	 	  : char;
    k		  : keyword;
    ks		  : set of keyword;
    TokenString	  : string;
  begin (*EndCheck*)
    TokenString := '                                        ';
    OldDot := GetDot;		(* Save dot *)
    Back2Indentation;
    IStart := GetDot;		(* Save start of indentation *)
    I := HorPos;

    IBuf := GetLine(0) ;
    while SpaceOrTab(GetNull(IBuf)) do IBuf := IBuf + 1;
    Index := 1;
    C := GetNull(IBuf);
    while (not Delim(C)) and (Index <= StrSize)
    do begin			(* Get first Token *)
      TokenString[Index] := UpCase(C);
      C := GetNull(IBuf + Index);
      Index := Index + 1;
    end;

    ks := Exdenters [MajorMode];

    ExDentline := false;
    for k := succ(FirstKeyword) to pred(LastKeyWord) do begin
      if k in ks then ExDentline := Exdentline or (TokenString = KeyWName[k]);
    end;
				(* Now let's see if we're really ExDenting *)
    if ExDentLine then begin
      SetDot( GetLine( -1 ) );	(* Only if line before has the same indent. *)
      Back2Indentation;		(* Does it hurt? *)
      ExDentLine := i >= HorPos; (* Only When We're Laughing... *)
    end;
    
    if ExDentLine then begin
      I := I - BlockILevel;
      SetDot(IStart);		(* Go to start of indentation *)
      DelHorSpace(-1);	(* Delete preceding blanks *)	
      TabTo(I);		(* Tab to our new column *)
      SetDot(OldDot - (Istart - GetDot)); (* Adjust and restore dot *)
    end else begin
      SetDot(OldDot);
    end;    
  end; (*EndCheck*)


  procedure FilLine;
  var
    P, Q :	bufpos;
  begin
    if HorPos > FillColumn then	(* If we need to break the line *)
    begin
      P := GetDot;		(* Save old dot *)
      Q := P;
      repeat			(* Scan for the beginning of the last word *)
	Q := Q - 1
      until (GetNull(Q) = ' ') or (Q = 0);
      if Q > GetLine(0) then	(* If the last word was not also the first *)
      begin
        SetDot(Q);		(* Position dot between the words *)
	DoFunction(FDelHorSpace, NoArgument);	(* Get rid of extra spaces *)
	InsEOL;			(* JE *)
	if FillPLength > 0 then	(* If we had a fill prefix.. *)
	  for I := 1 to FillPLength do
	    Insert(FillPrefix[I]); (* Insert it *)
	SetDot(GetDot-Q-1+P);	(* Reposition dot *)
      end;
    end;
  end;

  procedure DFWallChart(Heading: String; TableFlag, First: Integer);
  var
    Last: integer;
    i, C: integer;
    f: Fcode;
    S: string;
  begin
    (*@TOPS: Last := First + 127; *)
    (*@VMS: Last := First + 255; *)
    InsEOL;
    InsString(Heading);		(* Insert the heading *)
    InsEOL; InsEOL;		(* New Lines *)
    for i := First to Last do
    begin
      C := i mod 256;
      case TableFlag of
        0: f := DispTab[i];
        1: f := CxTable[i];
        2: f := VTTable[i]
      end;
      if not ((f = FUnused) or (f = FIllegal) or (f = FSelfInsert)) then
      begin
	if C = Backspace then
	  InsString('Backspace                               ')
	else if C = HorizontalTab then
	  InsString('Tab                                     ')
	else if C = LineFeed then
	  InsString('Linefeed                                ')
	else if C = CarriageReturn then
	  InsString('Return                                  ')
	else if C = Escape then
	  InsString('Escape                                  ')
	else if C = ord(' ') then
	  InsString('Space                                   ')
	else if C = Rubout then
	  InsString('Rubout                                  ')
	else if C < ord(' ') then
	begin
	  Insert('^');
	  Insert(Chr(C + Ord('@')))
	end
	else
	  Insert(Chr(C));
	TabTo(16);
	InsString(FuncName[f]);
	InsEOL
      end
    end;
    if Last > 127 then
      Insert(Chr(FormFeed));	(* A hack *)
  end;

(* ToggleMinor toggles one minor mode.					     *)

  procedure ToggleMinor(Mode: minors);

  begin (* ToggleMinor *)
    if (Arg <> Noargument) and (Arg <= 0) or (* Change according to argument *)
       (Arg = Noargument) and (Mode in Minormodes) (* ..or toggle. *)
    then SetMinor(MinorModes - [Mode])
    else SetMinor(MinorModes + [Mode])
  end (* ToggleMinor *);

begin (* DoFunction *)
  Argument := Arg;		(* Copy the argument *)
  if Argument = NoArgument then (* Argument missing? *)
    Argument := 1;		(* Yes, make it 1 *)

  FuncCount := FuncCount + 1;	(* Bump the function counter *)

  LastFunc := Func;		(* Remember what the last function was *)

  case Func of			(* Big list of *ALL* commands *)
FAbort:			(*** Abort ***)
    begin
      if RecLevel <= 1		(* Can't abort from top level *)
      then Error('ATL? Already at top level               ');
      EchoClear;
      EchoString('Abort this recursive edit               '); 
      if YesOrNo		(* Ask a question first *)
      then begin
	RecExitFlag := true;	(* Exit from this command level, *)
	RecAbortFlag := true	(* and abort function *)
      end;
      EchoClear
    end;
FAda:			(*** ADA Mode ***)
    SetMajor(AdaMode);
FAlgol:			(*** Algol Mode ***)
    SetMajor(AlgolMode);
FApropos:		(*** Apropos ***)
    Apropos;
FAutoFill:		(*** Auto Fill Mode ***)
    ToggleMinor(FillMode);
FBlissMode:		(*** BLISS Mode ***)
    SetMajor(BlissMode);
FCMode:			(*** C Mode ***)
    SetMajor(CMode);
FCompileExit:		(*** Compile ***)
    begin
      EchoClear;
      EchoUpdate;
      if GetModified then begin
        WriteFile(CurrName^.FileName,0,GetSize);
	EchoUpDate;
        TTyWrite(Chr(CarriageReturn));
        TTyWrite(Chr(LineFeed))	(* Hack to get new line *)
      end;
      RunCom(CurrName^.FileName, MajorName[MajorMode]);
    end;
FConnect:		(*** Connect to Directory ***)
    begin
      ReadLine('Connect to Directory:                   ', s, IVoid);
      DiskCheck(DskCD(s));
    end;
FDateEdit:		(*** Date Edit ***)
    DateEdit;
FDescribe:		(*** Describe ***)
    DHelp;
FDetach:		(*** Detach ***)
    begin
      EchoClear;
      EchoUpdate;
      Detach
    end;
FFindFile:		(*** Find File ***)
    FindFile;
FFundamental:		(*** Fundamental Mode ***)
    SetMajor(FunMode);
FHackmatic:		(*** Hackmatic Terminal ***)
    begin
      HackmaticMode :=
        (Arg <> Noargument) and (Arg > 0) or
        (Arg = Noargument) and (not HackmaticMode);
      TTyHacker(HackmaticMode);
      if HackmaticMode
      then EchoString('Hackmatic mode on                       ')
      else EchoString('Hackmatic mode off                      ');
    end;
FHowMany:		(*** How Many ***)
    HowMany;
FIndTabs:		(*** Indent Tabs Mode ***)
  begin
    UsingTabs :=
       (Arg <> Noargument) and (Arg > 0) or (* Change according to argument *)
       (Arg = Noargument) and (not UsingTabs); (* ..or toggle. *)
    if UsingTabs then
      EchoString('Using tabs                              ')
    else
      EchoString('Not using tabs                          ')
  end;
FInsertBuffer:		(*** Insert Buffer ***)
    DFInsBuffer;
FInsertDate:		(*** Insert Date ***)
    begin
      OldDot := GetDot;		(* Save dot *)
      DayTime(s);		(* Get date and time string *)
      InsString(s);		(* Insert it *)
      SetMark(GetDot);		(* Set mark after string *)
      SetDot(OldDot);		(* and set dot before *)
    end;
FInsertFile:		(*** Insert File ***)
    begin
      EchoClear;
      ReadFName('Insert File:                            ', s, IVoid);
      EchoClear;
      EchoUpdate;
      p := GetDot;
      ReadFile(s, false);
      SetMark(GetDot);
      SetDot(p);
    end;
FKillBuffer:		(*** Kill Buffer ***)
    DFKillbuffer;
FLispMode:		(*** Lisp Mode ***)
    SetMajor(LispMode);
FListBuffers:		(*** List Buffers ***)
    ListBuffers;
FListFiles:		(*** List Files ***)
    ListFiles(Arg <> NoArgument);
FListMatching:		(*** List Matching Lines ***)
    Occur;
FMacro:			(*** MACRO Mode ***)
    SetMajor(MacroMode);
FModula:		(*** Modula-2 Mode ***)
    SetMajor(ModulaMode);
FKbdName:		(*** Name Kbd Macro ***)
    DFKbdName;
FOverWrite:		(*** Overwrite Mode ***)
    ToggleMinor(OvWMode);
FPascal:		(*** Pascal Mode ***)
    SetMajor(PascalMode);
FPOM:			(*** Phase Of Moon ***)
    begin
      GetPOM(s); InsString(s);
    end;
FPL1:			(*** PL/1 Mode ***)
    SetMajor(PL1Mode);
FPushToExec:		(*** Push to EXEC ***)
    begin
      EchoClear;		(* Clear the echo line *)
      EchoUpdate;
      if Arg <> NoArgument	(* Any arg *)
      then begin		(* Yep, use it as break char *)
	if arg < 0		(* Negative? *)
	then TrmFreeze;		(* Yes, lock upper screen half *)
	I := abs(Arg);		(* Use the magnitude as break char *)
      end
      else I := -1;		(* Nope, no break char *)
      if PPush(I)		(* Start a new subprocess *)
      then Refresh
      else Error('CPC? Couldn''t Push Command level        ')
    end;
FQReplace:		(*** Query Replace ***)
    begin
      QueryReplace(true, Arg <> NoArgument);
      ModeChanged := true	(* The mode line may have changed *)
    end;
FRenameBuffer:		(*** Rename Buffer ***)
    RenBuffer;
FReplace:		(*** Replace String ***)
    QueryReplace(false, Arg <> NoArgument);
FSelectBuffer:		(*** Select Buffer ***)
    begin
      if Arg = NoArgument
      then begin
	EchoClear;
	SelBuffer(AskBuffer('Select Buffer:                          ',
			    PrevName, true));
      end
      else SelBuffer(NumFBuffer(arg));
      ModeChanged := true;
    end;
FSetEndComm:		(*** Set Comment End ***)
    begin
      EchoClear;
      ReadLine('New comment end:                        ',
	       CEndString [MajorMode],
	       CEndLength [MajorMode]);
      EchoClear;
    end;
FSetStartComm:		(*** Set Comment Start ***)
    begin
      EchoClear;
      ReadLine('New comment start:                      ',
	       CBeginString [MajorMode],
	       CBeginLength [MajorMode]);
      EchoClear;
    end;
FSetFlags:		(*** Set Flags ***)
    SetBehaviour;
FSetIndentLevel:	(*** Set Indent Level ***)
    BlockILevel := Argument;
FSetKey:		(*** Set Key ***)
    SetKey(Arg);
FSetFileName:		(*** Set Visited File Name ***)
    begin
      EchoClear;
      ReadLine('New File Name:                          ', S, IVoid);
      i := DskOpen(S, 'R');	(* Fake open file, to get true name *)
      TrueName(S, 'F');
      if i = 0 then IVoid := DskClose; (* Close the file, if it is open *)
      Currname^.FileName := S;	(* Set current file name to S *)
      CurrName^.NoFileName := false; (* Remember we got a file name now *)
      ModeChanged := true;	(* Mode line have changed (i think) *)
    end;
FStripSOSNum:		(*** Strip SOS Line Numbers ***)
    StripSOSNumbers;
FSwedish:		(*** Swedish Mode ***)
    ToggleMinor(SwedMode);	(* Toggle Swedish Mode *)
FTabify:		(*** Tabify ***)
    begin
      if arg = NoArgument	(* Default tabsize of 8 *)
	then argument := 8;
      p := GetDot;		(* Save dot *)
      q := GetSize;
      SetDot(q);
      while q > p do		(* To the beginning *)
      begin
	if GetNull(q-1) = ' ' then
	begin			(* If we found a space *)
	  SetDot(q);
	  if (HorPos mod argument = 0) then (* If we are at a tabstop *)
	  begin
	    i := 0;		(* How many are before us? *)
	    while (GetNull(q-1-i) = ' ') and (q-i > p) do
	      i := i + 1;
	    if i > 2 then	(* If more than two then *)
	    begin		(* delete them and tab *)
	      Delete(-i);
	      while i > 0 do
	      begin
	        Insert(Chr(HorizontalTab));	(* Insert tabs *)
		i := i - argument
	      end
	    end;
	    q := q - i;		(* Skip forward *)
	  end
	  else
	    q := q - 1;
	end
	else
          q := q - 1;
      end;
      SetDot(p);
    end;
FTeXMode:		(*** TeX Mode ***)
    SetMajor(TeXMode);
FText:			(*** Text Mode ***)
    SetMajor(TextMode);
FUndo:			(*** Undo ***)
    DFUndo;
FUnTabify:		(*** Untabify ***)
    begin
      if arg = NoArgument then	(* Default TAB is 8 *)
        argument := 8;
      p := GetDot;		(* Start at dot *)
      q := p;
      while q < GetSize do	(* Until we reach the end *)
      begin
	if GetChar(q) = chr(HorizontalTab) then	(* If we have a TAB *)
	begin
	  SetDot(q);		(* Delete it, and insert spaces *)
	  Delete(1);
	  for i := 1 to (argument - HorPos mod argument) do
	    Insert (' ');
	  q := GetDot
	end
	else
	  q := q + 1;
      end;
      SetDot(p)
    end;
FViewFile:		(*** View File ***)
    begin
      EchoClear;
      ReadFName('View File:                              ', s, IVoid);
      ViewFile(s);
    end;
FKbdView:		(*** View Kbd Macro ***)
    KbdView(0);
FViewQRegister:		(*** View Q-Register ***)
    NotYetError;
FWallChart:		(*** Wall Chart ***)
    begin			(* Start by creating a buffer to work in *)
      SelBuffer(StrFBuffer('AMIS Command Chart Buffer               ', true));
      SetDot(0); Delete(GetSize); (* Clear the buffer *)
      InsString('AMIS Command Chart (as of               '); (* Insert text *)
      Insert(' ');
      DayTime(S);		(* Get time and date *)
      InsString(S);		(* Insert it. *)
      Insert(')');
      Insert(':');
      InsEOL;
      DFWallChart('Non-Control Non-Meta Characters:        ', 0,   0);
      DFWallChart('Control Characters:                     ', 0, 512);
      DFWallChart('Meta Characters:                        ', 0, 256);
      DFWallChart('Control-Meta Characters:                ', 0, 768);
      DFWallChart('Control-X Subcommands:                  ', 1,   0);
      GetFSpec(S, 3);		(* AMIS.CHART *)
      WriteFile(S, 0, GetSize);
      SetModified(false);
      SelBuffer(PrevName);
    end;
FWhatCursorPos:		(*** What Cursor Position ***)
    DFWhatCursorPos;
FWhatDate:		(*** What Date ***)
    begin
      DayTime(s);
      EchoString(s);
    end;
FWhatPage:		(*** What Page ***)
    DFWhatPage;
FWhatVersion:		(*** What Version ***)
    begin
      GetVersion(S);		(* Ask system dependent module. *)
      EchoString(S);		(* Print answer in echo area. *)
    end;
FWhereIs:		(*** Where Is ***)
    WHelp;
FWriteFile:		(*** Write File ***)
    DFWriteFile;
FWriteRegion:		(*** Write Region ***)
    DFWriteRegion;
FXonXoff:		(*** XonXoff Mode ***)
    begin
      UsingXonXoff :=
	(Arg <> Noargument) and (Arg > 0) or
	(Arg = Noargument) and (not UsingXonXoff);
      if UsingXonXoff
      then EchoString('Using flow control                      ')
      else EchoString('Not using flow control                  ');
      XonAssign;		(* Reassign keys, and tell operating system. *)
    end;
FAppendNextKill:	(*** ^R Append Next Kill ***)
    KillIndex := FuncCount;	(* Make him believe this was a kill *)
FArgumentDigit:		(*** ^R Argument Digit ***)
    begin
      ArgFlag := true;		(* Now we have an argument *)
      ArgKeep := true;		(* ..and we want to keep it *)
      CheckArg(ArgArg);		(* Check the argument size *)
      ArgArg := ArgArg*10 + Ord(LastKey) mod 16; (* Accumulate argument *)
      ArgDigits := true;	(* We have digits *)
      ArgWrite;			(* Write out the argument *)
      FuncCount := FuncCount - 1 (* Don't count this as a command *)
    end;
FFillSpace:		(*** ^R Auto-Fill Space ***)
    begin
      if Argument < 2 then	(* If the argument is not greater than 1 *)
        FilLine;		(* Break the line, if necessary *)
      DoFunction(FSelfInsert,Arg)
    end;
FAutoArgument:		(*** ^R Autoargument ***)
    begin
      ArgFlag := true;		(* Now we have an argument *)
      ArgKeep := true;		(* and we want to keep it, too *)
      C := LastKey;		(* Get last character typed *)
      if C = '-' then begin	(* Minus sign? *)
	ArgSign := - ArgSign;	(* Complement argument sign *)
	C := ReadC;		(* Read next character *)
	if c in ['0'..'9'] then	(* Testing... *)
	AutoLast(true);		(* Auto-echo it. *)
      end;
      while C in ['0'..'9'] do begin
	CheckArg(ArgArg);
	ArgArg := ArgArg * 10 + Ord(C) - Ord('0');
	ArgDigits := true;
	C := ReadC;		(* Read next character *)
	if c in ['0'..'9'] then	(* Testing... *)
	AutoLast(true);		(* Auto-echo it. *)
      end;
      FuncCount := FuncCount - 1; (* Don't count this as a command *)
      ReRead;			(* We want to read the last character again *)
    end;
FBackToIndent:		(*** ^R Back to Indentation ***)
    Back2Indentation;
FBwdChar:		(*** ^R Backward Character ***)
    DoFunction(FFwdChar, -Argument);
FBwdDelChar:		(*** ^R Backward Delete Character ***)
    begin
      if (OvWMode in MinorModes) and (Arg = NoArgument) and
	 (GetLine(0) <> GetDot) then
      begin			(* Overwrite mode, no argument and not at *)
				(* the beginning of a line. *)
	Insert(' ');		(* Insert the space to replace *)
	SetDot(GetDot - 1);	(* Back over the space *)
	ExpTabs(-1)		(* Expand any tab before dot *)
      end;
      if Arg = NoArgument	(* Save in kill buffer if argument given.    *)
      then Delete(Chars(- 1))
      else begin
	KillCheck;
	Kill(Chars(- Argument));
      end;
    end;
FBwdDelHackTab:		(*** ^R Backward Delete Hacking Tabs ***)
    if Argument < 0 then
      DoFunction(FDelChar, - Arg) (* Negative argument, do ordinary del. *)
    else begin
      if Arg = NoArgument
      then begin
	ExpTabs(-1);
	DoFunction(FBwdDelChar, NoArgument)
      end else
      for I := 1 to Argument do	(* Specified number of times.. *)
      begin
        ExpTabs(-1);		(* Expand tab before dot *)
        DoFunction(FBwdDelChar, 1) (* ..and delete a character *)
      end;
    end;
FBwdKilWord:		(*** ^R Backward Kill Word ***)
    begin
      KillCheck;
      Kill(Words(-Argument))
    end;
FBwdKilSentence:	(*** ^R Backward Kill Sentence ***)
    begin
      KillCheck;
      Kill(Sentences(-Argument))
    end;
FBwdList:		(*** ^R Backward List ***)
    SetDot(GetDot + List(-Argument));
FBwdParagraph:		(*** ^R Backward Paragraph ***)
    SetDot(GetDot + Paragraphs(-Argument));
FBwdSentence:		(*** ^R Backward Sentence ***)
    SetDot(GetDot + Sentences(-Argument));
FBwdWord:		(*** ^R Backward Word ***)
    SetDot(GetDot + Words(-Argument));
FBegLine:		(*** ^R Beginning of Line ***)
    SetDot(GetLine(Argument-1));
FBufNotModified:	(*** ^R Buffer Not Modified ***)
    begin
      SetModified(false);
      ModeChanged := true	(* Remember to update mode line *)
    end;
FCenterLine:		(*** ^R Center Line ***)
    CentLines(Argument);
FCopyRegion:		(*** ^R Copy Region ***)
    begin
      KillCheck;		(* Check for kill buffer clearing *)
      B := GetModified;		(* Save the modification flag *)
      OldDot := GetDot;		(* Save dot *)
      QX(TempRegister, GetMark(false) - GetDot); (* Save region *)
      Kill(GetMark(false) - GetDot); (* Attach region to the kill buffer *)
      QG(TempRegister);		(* Get the region back *)
      QX(TempRegister, 0);	(* Wipe temp register *)
      SetDot(OldDot);		(* Restore the dot *)
      SetModified(B)
    end;
FCountLinesPage:	(*** ^R Count Lines Page ***)
    CountLines(Arg <> NoArgument);
FCrLf:			(*** ^R CRLF ***)
    begin
      if Exdenters [MajorMode] <> [] then EndCheck;
      if FillMode in MinorModes then FilLine;
      MakeNewLines(Argument)
    end;
FDelBlankLines:		(*** ^R Delete Blank Lines ***)
    begin
      SetDot(EndLine);		(* Start at end of current line.	     *)
      DelHorSpace(- 1);		(* Delete all spaces and tabs at end of line.*)
      Delete(BlankLines(1, false));(* Delete all blank lines after this line.*)
      Delete(BlankLines(- 1, false)) (* Delete all blank lines before this.  *)
    end;
FDelChar:		(*** ^R Delete Character ***)
    begin
      if Arg = NoArgument	(* Save in kill buffer if argument given.    *)
      then Delete(Chars(1))
      else begin
	KillCheck;
	Kill(Chars(Argument));
      end;
    end;
FDelHorSpace:		(*** ^R Delete Horizontal Space ***)
    DelHorSpace(0);		(* Delete spaces and tabs aroun dot.	     *)
FDelIndentation:	(*** ^R Delete Indentation ***)
    begin
      if Arg = NoArgument
      then begin
	SetDot(GetLine(0));	(* Concatenate current line with previous.   *)
	if GetDot > 0
	then Delete(- EOLSize)
      end
      else begin
	SetDot(EndLine);	(* Concatenate current line with next.	     *)
	if GetDot < GetSize
	then Delete(EOLSize)
      end (* if *);
      DelHorSpace(0);		(* Remove spaces and tabs.		     *)
      Insert(' ')		(* Insert a space between words.	     *)
    end;
FCDescribe:		(*** ^R Describe ***)
    CHelp;
FDocumentation:		(*** ^R Documentation ***)
    Helper;
FDownCommLine:		(*** ^R Down Comment Line ***)
    DownCommentLine(Argument);
FDownLine:		(*** ^R Down Real Line ***)
    begin
      DownLine(Argument);
      DownIndex := FuncCount;
    end;
FEndLine:		(*** ^R End of Line ***)
    begin
      SetDot(GetLine(Argument-1));
      SetDot(EndLine)
    end;
FKbdEnd:		(*** ^R End Kbd Macro ***)
    KbdEnd(Argument, Arg <> NoArgument);
FExchange:		(*** ^R Exchange Point and Mark ***)
    begin
      P := GetDot;
      SetDot(GetMark(true));
      SetMark(P)
    end;
FKbdExecute:		(*** ^R Execute Kbd Macro ***)
    KbdExecute(0, Argument);
FExit:			(*** ^R Exit ***)
    RecExitFlag := true;
FExtend:		(*** ^R Extended Command ***)
    begin
      EchoClear;		(* Clear the echo line *)
      if Abs(Arg) <> NoArgument then (* If an argument was given.. *)
      begin
	EchoDec(Argument);	(* Output the argument *)
        EchoWrite(' ')
      end;
      EchoString('M-X                                     ');
      DoFunction(ReadFunc, Arg)	(* Read a function name, and do it *)
    end;
FFillRegion:		(*** ^R Fill Region ***)
    begin
      AllowUndo;		(* Allow this to be undone *)
      RegionFill(Arg <> NoArgument);
    end;
FFillParagraph:		(*** ^R Fill Paragraph ***)
    begin
      DoFunction(FMarkParagraph, 1);
      LastFunc := FFillParagraph;
      AllowUndo;
      RegionFill(Arg <> NoArgument)
    end;
FFwdChar:		(*** ^R Forward Character ***)
    SetDot(GetDot + Chars(Argument));
FFwdList:		(*** ^R Forward List ***)
    SetDot(GetDot + List(Argument));
FFwdParagraph:		(*** ^R Forward Paragraph ***)
    SetDot(GetDot + Paragraphs(Argument));
FFwdSentence:		(*** ^R Forward Sentence ***)
    SetDot(GetDot + Sentences(Argument));
FFwdWord:		(*** ^R Forward Word ***)
    SetDot(GetDot + Words(Argument));
FGetQRegister:		(*** ^R Get Q-reg ***)
    begin
      P := GetDot;		(* Save dot *)
      QG(GetQName);		(* Get contents of some Q-Register *)
      Q := GetDot;		(* Get our current dot *)
      if arg = NoArgument	(* If we have no argument ... *)
      then setmark(P)		(*  then set mark before inserted text *)
      else begin
        SetMark(Q);		(*  else set mark after ... *)
	SetDot(P)		(*  and dot before *)
      end
    end;
FGoToBeg:		(*** ^R Goto Beginning ***)
    begin
      SetMark(GetDot);		(* Set mark to old value of dot *)
      SetDot(0)
    end;
FGoToEnd:		(*** ^R Goto End ***)
    begin
      SetMark(GetDot);		(* Set mark to old value of dot *)
      SetDot(GetSize)
    end;
FGrowWindow:		(*** ^R Grow Window ***)
    WinGrow(Argument);
FISearch:		(*** ^R Incremental Search ***)
    begin
      P := GetDot;		(* Save old dot *)
      IncrementalSearch(true, Argument);	(* Forward i-search *)
      if Abs(P - GetDot) > PushPoint then	(* Moved far? *)
      begin
        SetMark(P);		(* Yes, set mark to old dot *)
	EchoString('*** Mark set ***                        ');
	EchoUpDate;
      end
      else
	EchoClear
    end;
FIndAlgol:		(*** ^R Indent Algol Stm ***)
    BlockIndent(AlgolMode);
FIndAda:		(*** ^R Indent ADA Stm ***)
    BlockIndent(ADAmode);
FIndBLISS:		(*** ^R Indent BLISS Stm ***)
    BlockIndent(BlissMode);
FIndC:			(*** ^R Indent C stm ***)
    BlockIndent(CMode);
FIndForComm:		(*** ^R Indent For Comment ***)
    IndForComment;
FIndForLisp:		(*** ^R Indent For Lisp ***)
    DFIndLisp;
FIndModula:		(*** ^R Indent Modula-2 Stm ***)
    BlockIndent(ModulaMode);
FIndNewComm:		(*** ^R Indent New Coment Line ***)
    NotYetError;
FIndNewLine:		(*** ^R Indent New Line ***)
    begin
      DoFunction(DispTab[CarriageReturn], 1);	(* Do CR *)
      if FillPLength = 0 then	(* If we didn't have a fill prefix *)
        DoFunction(DispTab[HorizontalTab], Argument)	(* Do TAB *)
      else
        for I := 1 to FillPLength do	(* We did have a fill prefix *)
	  Insert(FillPrefix[I])
    end;
FIndPascal:		(*** ^R Indent Pascal Stm ***)
    BlockIndent(PascalMode);
FIndPL1:		(*** ^R Indent PL/1 Stm ***)
    BlockIndent(PL1Mode);
FIndRegion:		(*** ^R Indent Region ***)
    begin
      GetRegion(OldDot, Q);		(* Get size of region *)
      J := RegLines(OldDot, Q);	(* And the number of lines in it *)
      if Arg = NoArgument		(* Default argument is 8 *)
        then Argument := 8;
      SetDot(Q);
      Back2Indentation;			(* Where in the last line, relative *)
      P := Q - GetDot;			(* the indentation is dot *)
      SetDot(OldDot);
      if OldDot = GetLine(0)		(* Do the first line *)
        then IndentLine(Argument);
      for I := 1 to J do		(* And the main block *)
        begin SetDot(GetLine(1)); IndentLine(Argument)
	end;
      if J>=0				(* If there was a seperate last line *)
        then
	  begin
	    SetDot(GetLine(1));
	    Back2Indentation;		(* Indent if indentation in region *)
	    if (P>0) or ((P=0) and (GetDot <> GetLine(0)))
	      then IndentLine(Argument)
	  end;
      SetMark(GetDot + P);		(* Set dot relatively correct *)
      SetDot(OldDot)
    end;
FIndRigidly:		(*** ^R Indent Rigidly ***)
    begin
      GetRegion(OldDot, Q);		(* Get size of region *)
      J := RegLines(OldDot, Q);	(* And the number of lines in it *)
      SetDot(Q);
      Back2Indentation;			(* Where in the last line, relative *)
      P := Q - GetDot;			(* the indentation is dot *)
      SetDot(OldDot);
      if OldDot = GetLine(0)		(* Do the first line *)
        then
	  begin
	    Back2Indentation;
	    IndentLine(HorPos+Argument);
	  end;
      for I := 1 to J do		(* And the main block *)
        begin
	  SetDot(GetLine(1));
	  Back2Indentation;
	  IndentLine(HorPos+Argument)
	end;
      if J>=0				(* If there was a seperate last line *)
        then
	  begin
	    SetDot(GetLine(1));
	    Back2Indentation;		(* Indent if indentation in region *)
	    if (P>0) or ((P=0) and (GetDot <> GetLine(0)))
	      then IndentLine(HorPos+Argument)
	  end;
      SetMark(GetDot + P);		(* Set dot relatively correct *)
      SetDot(OldDot)
    end;
FIndSEXP:		(*** ^R Indent SEXP ***)
    DFIndSEXP;
FCSISequence:		(*** ^R Interpret CSI Sequence ***)
    begin
      GetCsiData(i, c);
      if (c = '~') and (i >= 0) and (i <= 35)
      then DoFunction(TildeTable[i], Arg)
      else DoFunction(VTTable[ord(c) mod 128], Arg);
    end;
FVT100Pad:		(*** ^R Interpret VT100 keypad ***)
    begin
      LastKey := ReadC;		(* Read next character *)
      AutoLast(true);		(* (???) Auto-echo it. *)
      FuncCount := FuncCount - 1;
      DoFunction(VTTable[Ord(LastKey)],Arg)
    end;
FKbdQuery:		(*** ^R Kbd Macro Query ***)
    KbdQuery;
FKillComment:		(*** ^R Kill Comment ***)
    for i := 1 to Argument do
    begin
      p := GetDot;		(* Save buffer position *)
      SetDot(GetLine(0));	(* Go to beginning of line *)
      j := CBeginLength[MajorMode]; (* Get length of comment start *)
      if LineSearch(CBeginString[MajorMode], j) then (* Is there a comment? *)
      begin
	SetDot(GetDot-j);	(* Position before the comment *)
	while SpaceOrTab(GetNull(GetDot - 1)) do (* Scan past indentation *)
          SetDot(GetDot - 1);
	KillPush;		(* Push the Kill Ring *)
	Kill(EndLine-GetDot);	(* Kill to end of line *)
      end
      else if Arg = NoArgument then (* If there was no comment, nor args: *)
        SetDot(p);		(* Restore dot. *)
      if Arg <> Noargument then (* If we were given an argument *)
        SetDot(GetLine(1))
    end;
FKilLine:		(*** ^R Kill Line ***)
    begin
      KillCheck;		(* Check if we should start a new killbuffer.*)
      if Arg = NoArgument	(* No argument means we should kill rest of  *)
      then			(* current line, if it is non blank, and the *)
      if BlankLines(1, true) = 0 (* rest of the line including the end of    *)
      then Kill(EndLine - GetDot) (* line sequency after the line.	     *)
      else Kill(GetLine(1) - GetDot) (* Numeric argument means we should kill*)
      else Kill(GetLine(Argument) - GetDot) (* that many lines after dot.    *)
    end;
FKillRegion:		(*** ^R Kill Region ***)
    begin
      KillCheck;		(* Check for kill buffer clearing *)
      GetRegion(P, Q);		(* Get the region *)
      SetDot(P);		(* Set dot to start of region *)
      Kill(Q - P);		(* Kill it *)
      SetMark(GetDot)		(* Set the mark to something sensible *)
    end;
FKillSentence:		(*** ^R Kill Sentence ***)
    begin
      KillCheck;
      Kill(Sentences(Argument))
    end;
FKillWord:		(*** ^R Kill Word ***)
    begin
      KillCheck;
      Kill(Words(Argument))
    end;
FLowCaseReg:		(*** ^R Lowercase Region ***)
    begin
      AllowUndo;		(* Allow this command to be undone *)
      ChgRegion(false);
    end;
FLowWord:		(*** ^R Lowercase Word ***)
    ChgCase(Argument, false, false);
FMakeParens:		(*** ^R Make () ***)
    begin
      if (arg = noargument) or (argument <= 0)
      then P := 0		(* Use words instead of S-exprs until *)
      else p := words(argument);(* someone writes that code ... *)
      Insert('(');
      SetDot(GetDot+P);
      Insert(')');
      SetDot(GetDot-P-1)
    end;
FMarkBeg:		(*** ^R Mark Beginning ***)
    SetMark(0);
FMarkEnd:		(*** ^R Mark End ***)
    SetMark(GetSize);
FMarkPage:		(*** ^R Mark Page ***)
    begin
      if Arg = NoArgument		(* Default argument is 0.	     *)
      then Argument := 0;
      if Argument <= 0			(* Pages doesn't like 0 argument.    *)
      then Argument := Argument - 1;
      SetDot(GetDot + Pages(Argument));	(* Set dot before page,		     *)
      SetMark(GetDot + Pages(1))	(* and mark after.		     *)
    end;
FMarkParagraph:		(*** ^R Mark Paragraph ***)
    begin
      SetDot(GetDot + Paragraphs(Argument));
      if Argument > 0
      then begin
        SetMark(GetDot);
	SetDot(GetMark(false) + Paragraphs(- 1))
	end
	else SetMark(GetDot + Paragraphs(1))
    end;
FMarkWhole:		(*** ^R Mark Whole Buffer ***)
    begin
      SetMark(GetDot);		(* Push the dot onto the Mark stack. *)
      if Arg = NoArgument then
      begin			(* Without args *)
	SetMark(GetSize);	(* Mark end of buffer *)
	SetDot(0)		(* Move to beginning *)
      end
      else
      begin			(* With arg *)
	SetMark(0);		(* Mark beginning of buffer *)
	SetDot(GetSize)		(* Move to end *)
      end
    end;
FMarkWord:		(*** ^R Mark Word ***)
    SetMark(GetDot + Words(Argument));
FMoveToEdge:		(*** ^R Move to Screen Edge ***)
    NotYetError;
FNegArgument:		(*** ^R Negative Argument ***)
    begin
      ArgFlag := true;		(* Now we have an argument *)
      ArgKeep := true;		(* ..and we want to keep it *)
      ArgSign := - ArgSign;	(* Negate the argument *)
      ArgWrite;			(* Write out the argument *)
      FuncCount := FuncCount - 1;
    end;
FNewWindow:		(*** ^R New Window ***)
    if Arg = NoArgument		(* Without argument ... *)
    then refresh		(* ... do a refresh. *)
    else if (ArgExp4 = 1) and (Arg = 4) (* C-U C-L ... *)
    then WinReWrite(1)		(* ... refresh one line. *)
    else			(* Others repositions window *)
      Winpos(argument);
FNextPage:		(*** ^R Next Page ***)
    SetDot(GetDot + Pages(Argument));
FNextScreen:		(*** ^R Next Screen ***)
    if Arg = NoArgument then begin (* If no argument supplied ... *)
      WinSize(J, I);		(* scroll out all but two lines of window *)
      winscroll(j-2);
      SetDot(WinTop)		(* Put dot at top of window *)
    end
    else
      winscroll(argument);
F1Window:		(*** ^R One Window ***)
    begin
      if WinCur = 2
      then begin
        WinSelect(1);
	if Antique then OtherBuffer;
      end; (* if *)
      if Arg <> NoArgument
      then OtherBuffer;
      WinNo(1)
    end;
FOtherWindow:		(*** ^R Other Window ***)
    begin
      WinSelect(0);
      OtherBuffer;
    end;
FOpenLine:		(*** ^R Open Line ***)
    begin
      if Argument > 0
      then begin
	for I := 1 to Argument	(* Open one or several lines.		     *)
	do InsEOL;
	SetDot(GetDot - Argument * EOLSize) (* Back over the blank lines.    *)
      end (* if *)
    end;
FPfxControl:		(*** ^R Prefix Control ***)
    begin
      AutoChar('C'); AutoChar('-');
      FuncCount := FuncCount - 1;
      ArgKeep := true;
      Prefix := [PfxControl];
    end;
FPfxCM:			(*** ^R Prefix Control-Meta ***)
    begin
      AutoChar('C'); AutoChar('-');
      AutoChar('M'); AutoChar('-');
      FuncCount := FuncCount - 1;
      ArgKeep := true;
      Prefix := [PfxControl, PfxMeta];
    end;
FPfxMeta:		(*** ^R Prefix Meta ***)
    begin
      AutoChar('M'); AutoChar('-');
      FuncCount := FuncCount - 1;
      ArgKeep := true;
      Prefix := [PfxMeta];
    end;
FPrevPage:		(*** ^R Previous Page ***)
    SetDot(GetDot + Pages(-Argument));
FPrevScreen:		(*** ^R Previous Screen ***)
    if Arg = NoArgument then begin (* If no argument supplied ... *)
      WinSize(J, I);		(* scroll out all but two lines of window *)
      winscroll(2-j);
      SetDot(WinTop)		(* Put dot at top of window *)
    end
    else
      winscroll(- argument);
FPutQRegister:		(*** ^R Put Q-reg ***)
    begin
      QX(GetQName,GetMark(false) - GetDot);
      if (ArgExp4 = 1) and (Arg = 4)
      then Delete(GetMark(false) - GetDot)
    end;
FQuit:			(*** ^R Quit ***)
    TopLoop;
FQInsert:		(*** ^R Quoted Insert ***)
    begin
      AutoLast(true);		(* Echo C-Q or equiv. *)
      LastKey := QReadC;	(* Get next character. *)
      AutoLast(false);		(* Auto-echo it. *)
      NInsert(LastKey, Argument); (* Insert it some times. *)
    end;
FReadFile:		(*** ^R Read File ***)
    DFReadFile(false);
FReturn:		(*** ^R Return to Superior ***)
    begin
      EchoSize(I, J);		(* Put cursor at bottom of screen *)
      EchoPos(I - 1, 0);
      EchoUpdate;		(* Update and force out *)
      Monitor;			(* Return to COMCON *)
      Refresh			(* ..and restore screen *)
    end;
FRSearch:		(*** ^R Reverse Search ***)
    DoFunction(FISearch, - Argument);
FSaveFile:		(*** ^R Save File ***)
    if GetModified then		(* Save file if buffer changed *)
    begin
      if CurrName^.NoFileName
      then DFWriteFile		(* Ask for file name and write that file *)
      else WriteFile(CurrName^.FileName, 0, GetSize);
      SetModified(false);
      ModeChanged := true	(* The modeline must have changed *)
    end 
    else
    begin
      EchoClear;		(* No changes, no update necessary *)
      EchoString('(No changes need to be written)         ')
    end;
FScrollOther:		(*** ^R Scroll Other Window ***)
    begin
      DoFunction(FOtherWindow, NoArgument); (* Select other window *)
      DoFunction(FNextScreen, Arg); (* Scroll the other window *)
      DoFunction(FOtherWindow, NoArgument) (* Return to first window *)
    end;
FSelfInsert:		(*** ^R Self Insert ***)
    begin
      if OvWMode in MinorModes
      then
      for I := 1 to Argument	(* Overwrite mode insert *)
      do begin
	if (EndLine <> GetDot) and (* At end of line? *)
	   ((GetNull(GetDot) <> Chr(HorizontalTab)) or
	    ((HorPos mod 8) = 7))	(* ..or close to a Tab *)
	then			(* No *)
	  Delete(1);		(* Delete the character to be overwritten *)
	Insert(LastKey)		(* Insert the new character *)
      end
      else NInsert(LastKey, Argument); (* Ordinary insert *)
      if LastKey in Rparens then ParMatch;
    end;
FSetCommColumn:		(*** ^R Set Comment Column ***)
    begin
      if Arg <> NoArgument then
        I := Argument
      else
        I := HorPos;
      CommColumn[MajorMode] := I;
      EchoClear;
(*** EchoMsg ***)
      EchoString('Comment column =                        ');
      EchoDec(I);
      EchoWrite(' ')
    end;
FSetFillColumn:		(*** ^R Set Fill Column ***)
    begin
      if Arg <> NoArgument then
        I := Argument
      else
        I := HorPos;
      FillColumn := I;		(* Set the fill column to value of argument *)
      EchoClear;
(*** EchoMsg ***)
      EchoString('Fill column =                           ');
      EchoDec(I);
      EchoWrite(' ')
    end;
FSetPrefixFill:		(*** ^R Set Fill Prefix ***)
    begin
      FillPLength := GetDot - GetLine(0);
      if FillPLength > StrSize then
        FillPLength := StrSize;	(* Maximize size of prefix string *)
      for I := 1 to FillPLength do
        FillPrefix[I] := GetChar(GetLine(0) + I - 1);
    end;
FSetPopMark:		(*** ^R Set/Pop Mark ***)
    if Argument = 16
    then begin
      P := GetMark(true) (* Pop current mark off the ring and throw it away. *)
    end
    else
    if Argument = 4
    then begin
      SetDot(GetMark(true)) (* Pop current mark off the ring into dot.	     *)
    end
    else begin
      SetMark(GetDot); (* Push current position onto the mark ring.	     *)
      EchoClear;
      if not Check(0)
      then EchoUpdate;
      EchoString('*** Mark set ***                        ')
    end;
FKbdStart:		(*** ^R Start Kbd Macro ***)
    KbdStart(Argument);
FSearch:		(*** ^R String Search ***)
    IncrementalSearch(false, Argument);
FToTabStop:		(*** ^R Tab to Tab Stop ***)
    repeat
      TabTo(HorPos div 8 * 8 + 8); (* Tab to next tab stop. *)
      Argument := Argument - 1;
    until Argument <= 0;
FTrnChar:		(*** ^R Transpose Characters ***)
    begin
      if (Arg = NoArgument) and (GetDot = EndLine) then
      begin
	C := GetChar(GetDot - 1);
	Delete(-1);
	SetDot(GetDot - 1);
	Insert(C);
	SetDot(GetDot + 1)
      end
      else
      begin
        for I := 1 to Abs(Argument) do
        begin
	  if Argument < 0 then
	    SetDot(GetDot - 1);
	  C := GetChar(GetDot - 1);
	  Delete(-1);
	  SetDot(GetDot + 1);
	  Insert(C);
	  SetDot(GetDot - 1);
	  if Argument > 0 then
	    SetDot(GetDot + 1)
	end;
	if Argument = 0 then
	begin
	  P := GetDot;
	  C := GetChar(P);
	  Insert(GetChar(GetMark(false)));
	  Delete(1);
	  SetDot(GetMark(false));
	  Delete(1);
	  Insert(C);
	  SetDot(P)
	end
      end
    end;
FTrnLines:		(*** ^R Transpose Lines ***)
    DFTrnLines;
FTrnRegions:		(*** ^R Transpose Regions ***)
    DFTrnRegions;
FTrnWords:		(*** ^R Transpose Words ***)
    DFTrnWords;
F2Windows:		(*** ^R Two Windows ***)
    begin
      if WinCur <> 1
      then OtherBuffer;
      WinNo(2);
      if (Argument > 1) or (not Antique)
      then OtherName := CurrName;
      WinSelect(2);
      OtherBuffer;
    end;
FUnKill:		(*** ^R Un-kill ***)
    begin
      if (ArgExp4 = 1) and (Arg = 4)
      then begin		(* We have special case for C-U C-Y *)
        UnKillMark := GetDot;
        UnKill(1);
        UnKillDot := GetDot;
	SetMark(UnKillDot);	(* Set mark after inserted text *)
	SetDot(UnKillMark)	(* and dot before *)
      end
      else begin		(* All other cases, including no argument *)
        UnKillMark := GetDot;
        UnKill(Argument);
        UnKillDot := GetDot;
	SetMark(UnKillMark)	(* Set mark before inserted text *)
      end
    end;
FUnKillPop:		(*** ^R Un-kill Pop ***)
    if (GetMark(false) = UnKillMark) and (GetDot = UnKillDot)
    then begin
      Delete(GetMark(false) - GetDot);
      UnKillMark := GetDot;
      if Argument <> 0 then
      begin
	KillPop;
	UnKill(1)
      end;
      UnKillDot := GetDot
    end;
FUnivArgument:		(*** ^R Universal Argument ***)
    begin
      AutoLast(true);		(* Make sure we echo. *)
      ArgArg := 0;
      ArgFlag := true;		(* We have some argument now *)
      ArgKeep := true;		(* ..and we want to keep it *)
      C := ReadC;		(* Read the next character *)
      if C in ['-', '0'..'9'] then begin
	AutoLast(true);		(* Auto-echo it. *)
	if C = '-' then begin
	  ArgSign := - ArgSign;	(* Complement argument sign *)
	  C := ReadC;
	  AutoLast(true);	(* Auto-echo it. *)
        end;
	while C in ['0'..'9'] do begin
	  CheckArg(ArgArg);	(* Check the argument size *)
	  ArgArg := ArgArg*10 + Ord(C) - Ord('0');
	  ArgDigits := true;
	  C := ReadC;
	  AutoLast(true);	(* Auto-echo it. *)
	end;
      end else
	ArgExp4 := ArgExp4 + 1;	(* Increment the exponent of four *)
      FuncCount := FuncCount - 1; (* Don't count this as a command *)
      ReRead;
    end;
FUpCommLine:		(*** ^R Up Comment Line ***)
    DownCommentLine(-Argument);
FUpLine:		(*** ^R Up Real Line ***)
    begin
      DownLine(-Argument);
      DownIndex := FuncCount;
    end;
FUpInitial:		(*** ^R Uppercase Initial ***)
    ChgCase(Argument, true, false);
FUpCaseReg:		(*** ^R Uppercase Region ***)
    begin
      AllowUndo;		(* Allow this command to be undone *)
      ChgRegion(true);
    end;
FUpWord:		(*** ^R Uppercase Word ***)
    ChgCase(Argument, true, true);
FVisitFile:		(*** ^R Visit File ***)
    DfReadFile(true);
FVisitInOther:		(*** ^R Visit in Other Window ***)
    begin
      i := WinCur;		(* Save the window that's current now *)
      DoFunction(F2Windows, NoArgument);
      if i <> 1 then DoFunction(FOtherWindow, NoArgument);
      C := ReadC;		(* Read in a character *)
      AutoLast(true);		(* Auto-echo it. *)
      while C = Chr(HelpChar) do begin
	WinOvTop;
	OvWString('You are typing a character as an        ');
	OvWString('argument to a command.                  '); OvWLine;
	OvWString('The command is ^R Visit in Other Window:'); OvWLine;
	OvWString('Find buffer or file in other window.    '); OvWLine;
	OvWString('Follow this command by B or C-B and a   ');
	OvWString('buffer name or F or C-F and a file name.'); OvWLine;
	OvWString('We find the buffer or file in the other ');
	OvWString('window,                                 '); OvWLine;
	OvWString('creating the other window if necessary. '); OvWLine;
	OvWLine;
	OvWString('Now type the argument.                  ');
	c := ReadC;		(* Get next character. *)
	AutoLast(true);		(* Auto-echo it. *)
      end;
      WinOvClear;
      if (C = Chr(CtrlB)) or (C = 'B') or (C = 'b') then
        DoFunction(FSelectBuffer, NoArgument)
      else if (C = Chr(CtrlF)) or (C = 'F') or (C = 'f') then
        DoFunction(FFindFile, NoArgument)
      else
        Error('ILO? Illegal Option for this command.   ')
    end;
FMacroExtend:		(*** Here for user named keybord macros. ***)
    KbdExecute(KbdRecMacro^.Number, Argument);
FMacroCharacter:	(*** Here for user macro assigned to a key ***)
    KbdExecute(FindMacro(LastTenBit), Argument);
FChrExtend:		(*** C-X commands go here ***)
    begin
      AutoLast(true);		(* Make sure we echo. *)
      LastKey := ReadC;		(* Read a character *)
      AutoLast(true);		(* Auto-echo it. *)
      FuncCount := FuncCount - 1; (* This is not really a command... *)
      f := CXTable[ord(LastKey)]; (* Get proper function code *)
      if f = FIllegal then begin
	if LastKey in ['A'..'Z'] then f := CXTable[ord(LastKey) + 32];
	if LastKey in ['a'..'z'] then f := CXTable[ord(LastKey) - 32];
      end;
      DoFunction(f,Arg);
    end;
FUnUsed:		(*** Unused Key ***)
    Error('UUK? UnUsed Key                         ');
FIllegal:		(*** Illegal commands go here ***)
    Error('ILC? Illegal Command                    ');
  end (*-of the BIG case statement-*)
end; (* DoFunction *)

(*---------------------------------------------------------------------------*)

procedure Init(Total: boolean);
begin				(* This module does all the initing *)
  TTyInit;			(* Init the TTY *)
  DskInit;			(* Init the disk I/O *)
  if Total then begin		(* Has once-only initing been done? *)
    BufInit;			(* Init the buffer handler *)
    New(ZeroName);		(* Create buffer 0 name block *)
    ZeroName^.Left := ZeroName;	(* Let it be the first and only element in *)
    ZeroName^.Right := ZeroName;(* the linked list *)
    SelBuffer(StrFBuffer('Main                                    ', true));
    PrevName := CurrName;	(* There was no previous buffer *)
    OtherName := nil;		(* There is no other window *)
  end;
  SeaInit(Total);		(* Init old search string *)
  TrmInit;			(* Init the terminal handler *)
  ScrInit(Total);		(* Init the screen handler *)
  InInit(Total);		(* Init the input/echo module *)
  Refresh;			(* Refresh the screen *)
  HackMaticMode := TtyMeta;	(* Get TERMINAL META (or whatever) setting *)
  UsingXonXoff := TTyProtocol;	(* Decide if to use ^S/^Q as commands *)
  XonAssign;			(* Do nice things *)
end;				(* Done initing *)

procedure InitFile;
var
  Code, Count: integer;
  filename: string;
  p: dskbp;
begin
  GetFSpec(filename, 7);	(* AMIS.INI<,> *)
  Code := DskOpen(filename, 'R');
  if Code <> DskWarning then begin
    DiskCheck(Code);
    Count := DskRead(p);
    while Count >= 0 do begin
      InsBlock(p, Count);
      Count := DskRead(p);
    end;
    DiskCheck(Count);
    DiskCheck(DskClose);
    SetDot(0);
    QX(-39, GetSize);		(* Ugly, isn't it? *)
    Delete(GetSize);
    SetModified(False);
    SetFile;			(* Tell massa. *)
  end;
end;

(*---------------------------------------------------------------------------*)

function GetFunc: fcode;
var 
  Cmd: integer;			(* The command, after adding prefixes *)
  CmdChar: char;		(* The given command character *)
  f: fcode;			(* Scratch function code *)
begin
  CmdChar := ReadC;		(* Read a character *)
  Cmd := Ord(CmdChar);
  if Prefix <> [] then AutoLast(false);
  if MetaBit then Prefix := Prefix + [PfxMeta];
  if PfxControl in Prefix then Cmd := Cmd + 512;
  if PfxMeta in Prefix then Cmd := Cmd + 256;
  Prefix := [];
  LastKey := CmdChar;
  f := DispTab[Cmd];
  if f = FIllegal then begin
    if CmdChar in ['A'..'Z'] then Cmd := Cmd + 32;
    if CmdChar in ['a'..'z'] then Cmd := Cmd - 32;
    if CmdChar < ' ' then begin
      if Cmd < 512
      then Cmd := Cmd + 512 + 64 (* Map M-^X to C-M-X *)
      else Cmd := Cmd + 64;	(* Map C-M-^X to C-M-X too *)
    end;
    f := DispTab[Cmd];
  end;
  LastTenBit := Cmd;
  GetFunc := f;
end;

(*---------------------------------------------------------------------------*)

function GetArg: integer;
var
  Arg, i: integer;
begin
  if not ArgFlag or not ArgKeep then
  begin				(* No argument given. Clear the variables *)
    ArgArg := 0;		(* Clear the argument *)
    ArgExp4 := 0;		(* Clear the exponent of four *)
    ArgSign := 1;		(* Set the sign to positive *)
    ArgDigits := false;		(* No digits seen *)
    ArgFlag := false;		(* We have no argument *)
    GetArg := NoArgument;	(* Return 'No Argument ' *)
  end else begin		(* Some argument given *)
    Arg := ArgArg;
    if not ArgDigits then	(* If no digits have been seen.. *)
      Arg := 1;			(* ..default to 1 *)
    for I := 1 to ArgExp4 do	(* Exponentiate *)
    begin
      CheckArg(Arg);		(* Check argument size *)
      Arg := Arg * 4;		(* Times four *)
    end;
    GetArg := ArgSign * Arg;	(* Set the sign of the argument *)
  end;
  ArgKeep := false;		(* No argument next time *)
end;

(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure CommandLoop(RecursiveName: string);
var
  ErrSave: catchblock;
begin				(* The Main Lupe *)
  RecLevel := RecLevel + 1;	(* Yet another recursive editing level *)
  RecName := RecursiveName;	(* Change recursive editing level name *)
  RecExitFlag := false;		(* Clear edit level exit flag *)
  RecAbortFlag := false;	(* Clear edit level abort flag *)
  ErrSave := Err;		(* Save catch context block *)
  BVoid := Catch(Err);		(* Make errors return here *)
  ArgFlag := false;		(* We are not inside an argument now *)
  Prefix := [];			(* Neither are we prefixed *)
  WinOvClear;			(* Clear window overwrite mode, if on *)
  ModeChanged := true;		(* Display the mode line *)
  repeat
    if ModeChanged then begin
      RecName := RecursiveName;
      ModeLine;
      ModeChanged := false;
    end;
    WinUpDate;			(* Request screen update *)
    DoFunction(GetFunc, GetArg); (* Do the function *)
    if (Prefix = []) and (not ArgFlag or not ArgKeep) then AutoReset;
  until RecExitFlag;
  ModeChanged := true;		(* Mode will have changed when we return *)
  RecLevel := RecLevel - 1;	(* Back to previous level *)
  RecExitFlag := false;		(* Clear edit level exit flag *)
  Err := ErrSave;		(* Restore catch context block *)
  if RecAbortFlag then begin
    RecAbortFlag := false;
    Throw(Err);			(* Abort executing function on outer level *)
  end;
end;
 
(*---------------------------------------------------------------------------*)

(*@VMS: [global] *)
procedure Main(Total: boolean);
var
  ParmsProcessed: boolean;	(* We have started to process parms. *)
  InitProcessed: boolean;	(* We have started to process init file. *)
begin (* Main *)
  Init(Total);			(* Initiate all the AMIS modules *)
  ParmsProcessed := false;	(* We have not processed any parameters yet *)
  InitProcessed := false;	(* Neither the init file *)
  BVoid := Catch(Err);		(* Rigth now, errors return here *)
  if Total then begin
    if not InitProcessed then begin
      Initprocessed := true;
      InitFile;
    end;
    if not ParmsProcessed then begin
      ParmsProcessed := true;
      if GetParameters then begin
	ReadFile(CurrName^.FileName, true);
	CurrName^.NoFileName := false;
	SetModified(false);	(* Reset the modification flag *)
	SetDot(0);		(* Go to the beginning of the buffer *)
	PosKludge;		(* Check for /Char:nn and such... *)
      end;
    end;
  end;
  BVoid := Catch(Err);		(* From now on, errors return here *)
  RecLevel := 0;		(* Start from recursive level zero *)
  CommandLoop('                                        '); (* Execute loop *)
  DoFunction(FReturn, NoArgument); (* Exit to monitor *)
  Throw(Err);
end;

(*---------------------------------------------------------------------------*)

(*@TOPS: begin end. *)
(*@VMS: end. *)
