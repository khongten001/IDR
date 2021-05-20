unit EditFunctionDlg;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics,
  Controls, Forms, Dialogs, StdCtrls, ExtCtrls, ComCtrls,
  Def_info;

type
  TFEditFunctionDlg=class(TForm)
    Panel1: TPanel;
    bEdit: TButton;
    bAdd: TButton;
    bRemoveSelected: TButton;
    pc: TPageControl;
    tsArgs: TTabSheet;
    lbArgs: TListBox;
    tsVars: TTabSheet;
    lbVars: TListBox;
    pnlVars: TPanel;
    rgLocBase: TRadioGroup;
    edtVarOfs: TLabeledEdit;
    edtVarSize: TLabeledEdit;
    edtVarName: TLabeledEdit;
    edtVarType: TLabeledEdit;
    bApplyVar: TButton;
    bCancelVar: TButton;
    tsType: TTabSheet;
    cbEmbedded: TCheckBox;
    mType: TMemo;
    rgCallKind: TRadioGroup;
    bApplyType: TButton;
    bCancelType: TButton;
    rgFunctionKind: TRadioGroup;
    bOk: TButton;
    cbVmtCandidates: TComboBox;
    cbMethod: TCheckBox;
    Label1: TLabel;
    lRetBytes: TLabel;
    Label2: TLabel;
    lArgsBytes: TLabel;
    lEndAdr: TLabeledEdit;
    lStackSize: TLabeledEdit;
    bRemoveAll: TButton;
    procedure FormKeyDown(Sender : TObject; var Key:Word; Shift: TShiftState);
    procedure bEditClick(Sender : TObject);
    procedure FormShow(Sender : TObject);
    procedure pcChange(Sender : TObject);
    procedure lbVarsClick(Sender : TObject);
    procedure bCancelVarClick(Sender : TObject);
    procedure bApplyVarClick(Sender : TObject);
    procedure bRemoveSelectedClick(Sender : TObject);
    procedure bAddClick(Sender : TObject);
    procedure bApplyTypeClick(Sender : TObject);
    procedure bCancelTypeClick(Sender : TObject);
    procedure bOkClick(Sender : TObject);
    procedure bRemoveAllClick(Sender: TObject);
    procedure FormClose(Sender : TObject; var Action:TCloseAction);
    procedure cbMethodClick(Sender : TObject);
  private
    { Private declarations }
    TypModified:Boolean;
    VarModified:Boolean;
    //ArgEdited:Integer;
    //VarEdited:Integer;
    VmtCandidatesNum:Integer;
    StackSize:Integer;
    SFlags:TProcFlagSet;
    SName:AnsiString;
    Procedure FillVMTCandidates;
    Procedure FillType;
    Procedure FillArgs;
    Procedure FillVars;
  public
    { Public declarations }
    Adr:Integer;
    EndAdr:Integer;
  end;

Var
  FEditFunctionDlg:TFEditFunctionDlg;

implementation

{$R *.DFM}

Uses Types,Infos,Misc,StrUtils,Def_main,Main,Def_know;

procedure TFEditFunctionDlg.bOkClick(Sender : TObject);
begin
  ModalResult:=mrOk;
end;

procedure TFEditFunctionDlg.FormKeyDown(Sender : TObject; var Key:Word; Shift: TShiftState);
begin
  if Key=VK_ESCAPE then ModalResult:=mrCancel;
end;

procedure TFEditFunctionDlg.FormShow(Sender : TObject);
var
  recN:InfoRec;
begin
  //ProcessMethodClick := false;

  recN := GetInfoRec(Adr);
  SFlags := recN.procInfo.flags;
  SName := recN.Name;
  EndAdr := Adr + recN.procInfo.procSize - 1;
  lEndAdr.Text := Val2Str(EndAdr);
  StackSize := recN.procInfo.stackSize;
  lStackSize.Text := Val2Str(StackSize);

  FillVMTCandidates;
  pc.ActivePage := tsType;
  //Type
  cbMethod.Enabled := false;
  cbVmtCandidates.Enabled := false;
  mType.Enabled := false;

  cbEmbedded.Enabled := false;
  lEndAdr.Enabled := false;
  lStackSize.Enabled := false;
  rgFunctionKind.Enabled := false;
  rgCallKind.Enabled := false;
  bApplyType.Enabled := false;
  bCancelType.Enabled := false;
  FillType;
  //Args
  lbArgs.Enabled := true;
  FillArgs;
  //Vars
  lbVars.Align := alClient;
  lbVars.Enabled := true;
  pnlVars.Visible := false;
  edtVarOfs.Text := '';
  edtVarSize.Text := '';
  edtVarName.Text := '';
  edtVarType.Text := '';
  FillVars;
  //Buttons
  bEdit.Enabled := true;
  bAdd.Enabled := false;
  bRemoveSelected.Enabled := false;
  bRemoveAll.Enabled := false;
  bOk.Enabled := false;

  TypModified := false;
  VarModified := false;
end;

procedure TFEditFunctionDlg.bEditClick(Sender : TObject);
var
  line,p:AnsiString;
  recN:InfoRec;
  locInfo:PLocalInfo;
begin
  if pc.ActivePage = tsType then
  begin
    cbMethod.Enabled := true;
    cbVmtCandidates.Enabled := true;
    mType.Enabled := true;
    cbEmbedded.Enabled := true;
    lEndAdr.Enabled := true;
    lStackSize.Enabled := true;
    rgFunctionKind.Enabled := true;
    rgCallKind.Enabled := true;
    bApplyType.Enabled := true;
    bCancelType.Enabled := true;
  end
  else if pc.ActivePage = tsVars then
  begin
    edtVarOfs.Text := '';
    edtVarName.Text := '';
    edtVarType.Text := '';
    recN:=GetInfoRec(Adr);
    locInfo:=recN.procInfo.locals[lbVars.ItemIndex];
    If Assigned(locInfo) Then
    begin
      edtVarOfs.Text:=IntToHex(locInfo.Ofs,0);
      edtVarSize.Text:=IntToStr(locInfo.Size);
      edtVarName.Text:=locInfo.Name;
      edtVarType.Text:=locInfo.TypeDef;
    end;
    {
    line := lbVars.Items[lbVars.ItemIndex];
    p := StrTok(line,[' ']);
    if p='' then Exit;
    //offset
    edtVarOfs.Text := p;
    //size
    p := StrTok('',[' ']);
    if p='' then Exit;
    edtVarSize.Text := p;
    //name
    p := StrTok('',[' ',':']);
    if p='' then Exit;
    if p<>'?' then edtVarName.Text := p;
    //type
    p := StrTok('',[' ']);
    if p='' then Exit;
    if p<>'?' then edtVarType.Text := p;
    VarEdited := lbVars.ItemIndex;
    lbVars.Align := alNone;
    }
    lbVars.Height := pc.Height - pnlVars.Height;
    pnlVars.Visible := true;
  end;
  lbArgs.Enabled := false;
  lbVars.Enabled := false;
  //Buttons
  bEdit.Enabled := false;
  bAdd.Enabled := false;
  bRemoveSelected.Enabled := false;
  bRemoveAll.Enabled := false;
end;

procedure TFEditFunctionDlg.lbVarsClick(Sender : TObject);
begin
  bEdit.Enabled := lbVars.SelCount = 1;
  bRemoveSelected.Enabled := (lbVars.SelCount > 0);
  bRemoveAll.Enabled := lbVars.Count > 0
end;

procedure TFEditFunctionDlg.pcChange(Sender : TObject);
begin
  if pc.ActivePage = tsType then
  begin
    bEdit.Enabled := true;
    bAdd.Enabled := false;
    bRemoveSelected.Enabled := false;
    bRemoveAll.Enabled := False;
  end
  else if pc.ActivePage = tsArgs then
  begin
    bEdit.Enabled := false;
    bAdd.Enabled := false;
    bRemoveSelected.Enabled := false;
    bRemoveAll.Enabled := false;
  end
  else
  begin
    bAdd.Enabled := false;
    bEdit.Enabled := (lbVars.SelCount = 1);
    bRemoveSelected.Enabled := (lbVars.SelCount > 0);
    bRemoveAll.Enabled := (lbVars.Count > 0);
  End;
end;

procedure TFEditFunctionDlg.bApplyTypeClick(Sender : TObject);
Var
  newEndAdr:Integer;
  recN:InfoRec;
  decl,_name,retType:AnsiString;
  n,p:Integer;
begin
  if cbMethod.Checked and (cbVmtCandidates.Text = '') then
  begin
    ShowMessage('Class name is empty');
    Exit;
  End;
  if (lEndAdr.Text = '') or not TryStrToInt('$' + lEndAdr.Text, newEndAdr) then
  begin
    ShowMessage('End address is not valid');
    Exit;
  End;
  newEndAdr:=StrToInt('$' + lEndAdr.Text);
  if not IsValidCodeAdr(newEndAdr) Then
  begin
    ShowMessage('End address is not valid');
    Exit;
  End;
  if (lStackSize.Text = '') or not TryStrToInt('$' + lStackSize.Text, StackSize) then
  begin
    ShowMessage('StackSize not valid');
    Exit;
  end;
  StackSize:=StrToInt('$' + lStackSize.Text);
  recN:=GetInfoRec(Adr);
  //Set new procSize
  recN.procInfo.procSize:=newEndAdr - Adr + 1;
  case rgFunctionKind.ItemIndex of
    0: recN.kind:=ikConstructor;
    1: recN.kind:=ikDestructor;
    2:
      Begin
        recN.kind:=ikProc;
        recN._type:='';
      end;
    3: recN.kind:=ikFunc;
  End;
  recN.procInfo.call_kind := rgCallKind.ItemIndex;

  if cbEmbedded.Checked then Include(recN.procInfo.flags, PF_EMBED)
    else Exclude(recN.procInfo.flags, PF_EMBED);
  decl:=AnsiReplaceStr(mType.Text,#13#10,' ');
  p:=Pos('(',decl);
  If p<>0 then _name:=Trim(Copy(decl,1,p-1))
  Else
  Begin
    p:=Pos(':',decl);
    If p<>0 then _name:=Trim(Copy(decl,1,p-1))
    else
    Begin
      p:=Pos(';',decl);
      if p<>0 then _name:=Trim(Copy(decl,1,p-1))
        else _name:=Trim(decl);
    end;
  end;
  if recN.kind = ikConstructor then
    recN.Name:=cbVmtCandidates.Text + '.Create'
  else if recN.kind = ikDestructor then
    recN.Name:=cbVmtCandidates.Text + '.Destroy'
  {else if SameText(_name, GetDefaultProcName(Adr)) then
  begin
    if cbMethod.Checked and (recN.procInfo.flags * PF_ALLMETHODS <> []) then
      recN.SetName(cbVmtCandidates.Text + '.' + _name)
    else recN.SetName('');
  end}
  else
  begin
    if cbMethod.Checked and (recN.procInfo.flags * PF_ALLMETHODS <> []) then
      recN.Name:=cbVmtCandidates.Text + '.' + ExtractProcName(_name)
    else recN.Name:=_name;
  End;
  recN.procInfo.DeleteArgs;
  n:=0;
  if (recN.kind = ikConstructor) or (recN.kind = ikDestructor) then
  begin
    recN.procInfo.AddArg($21, 0, 4, 'Self', cbVmtCandidates.Text);
    recN.procInfo.AddArg($21, 1, 4, '_Dv__', 'Boolean');
    n:=2;
  end
  else if cbMethod.Checked {recN.procInfo.flags * PF_ALLMETHODS <> []} then
  begin
    recN.procInfo.AddArg($21, 0, 4, 'Self', cbVmtCandidates.Text);
    n:=1;
  end;
  p:=Pos('(',decl);
  If p<>0 then retType:=recN.procInfo.AddArgsFromDeclaration(decl, n, rgCallKind.ItemIndex)
  Else
  Begin
    p:=Pos(':',decl);
    if p<>0 Then
    begin
      n:=PosEx(';',decl,p);
      if n=0 then n:=Length(decl)+1;
      retType:=Copy(decl,p+1,n-p-1);
    End
    Else retType:='';
  end;
  if recN.kind = ikFunc then
  Begin
    if retType<>'' then recN._type:=retType
    Else
    Begin
      ShowMessage('Missing result type for function');
      Exit;
    end;
  End;
  recN.procInfo.stackSize:=StackSize;
  FillType;
  FillArgs;

  cbMethod.Enabled:=false;
  mType.Enabled:=false;
  cbEmbedded.Enabled:=false;
  lEndAdr.Enabled:=false;
  lStackSize.Enabled:=false;
  rgFunctionKind.Enabled:=false;
  rgCallKind.Enabled:=false;
  bApplyType.Enabled:=false;
  bCancelType.Enabled:=false;
  //Buttons
  bEdit.Enabled:=true;
  bAdd.Enabled:=false;
  bRemoveSelected.Enabled:=false;
  bRemoveAll.Enabled:=false;
  bOk.Enabled:=true;

  TypModified:=true;
end;

procedure TFEditFunctionDlg.bCancelTypeClick(Sender : TObject);
var
  recN:InfoRec;
begin
  if not TypModified then
  begin
    recN := GetInfoRec(Adr);
    recN.SetName(SName);
    recN.procInfo.flags := SFlags;
  End;
  FillType;
  cbMethod.Enabled := false;
  cbVmtCandidates.Enabled := false;
  mType.Enabled := false;
  cbEmbedded.Enabled := false;
  lEndAdr.Enabled := false;
  lStackSize.Enabled := false;
  rgFunctionKind.Enabled := false;
  rgCallKind.Enabled := false;
  bApplyType.Enabled := false;
  bCancelType.Enabled := false;
  //Buttons
  bEdit.Enabled := true;
  bAdd.Enabled := false;
  bRemoveSelected.Enabled := false;
  bRemoveAll.Enabled:=False;
  bOk.Enabled := false;
  TypModified := false;
end;

procedure TFEditFunctionDlg.bApplyVarClick(Sender : TObject);
Var
  recofs,size,pos1,pos2,elofs,len1:Integer;
  recFile:TextFile;
  p:PAnsiChar;
  fname,ftype,_name,_type,recFileName,ofs,str:AnsiString;
  recN:InfoRec;
  locInfo:PLocalInfo;
  tInfo:MTypeInfo;
  _uses:TWordDynArray;
begin
  try
    recofs := StrToInt('$'+Trim(edtVarOfs.Text));
  Except
    on E:Exception do
    begin
      ShowMessage('Invalid offset');
      edtVarOfs.SetFocus;
      Exit;
    End;
  End;
  try
    size := StrToInt('$'+Trim(edtVarSize.Text));
  Except
    on E:Exception do
    begin
      ShowMessage('Invalid size');
      edtVarSize.SetFocus;
      Exit;
    end;
  End;
  {
  item := edtVarName.Text;
  if item <> '' then line:=line + item
    else line:=line + '?';
  line:=line + ':';
  item := edtVarType.Text;
  if item <> '' then line:=line + item
    else line:=line + '?';

  lbVars.Items[VarEdited] := line;
  lbVars.Update;
  }

  //Insert by ZGL
  recN := GetInfoRec(Adr);
  locInfo := recN.procInfo.locals[lbVars.ItemIndex];
  ////////////

  recofs := locInfo.Ofs;
  fname := Trim(edtVarName.Text);
  locInfo.Name := fname;  //ZGL add
  ftype := Trim(edtVarType.Text);
  locInfo.TypeDef := ftype;  //ZGL add
  recN.procInfo.SetLocalType(recofs, ftype);
  { ===== replaced by SetLocalType() ======
  if (ftype <> '') and (GetTypeKind(ftype, size) = ikRecord) then
  begin
    recFileName := FMain.WrkDir + '\types.idr';
    if FileExists(recFileName) then
    begin
      AssignFile(recFile,recFileName);
      Reset(recFile);
      while Not Eof(recFile) do
      begin
        ReadLn(recFile,str);
        if Pos(ftype + '=',str) = 1 then
        begin
          while not eof(recFile) do
          begin
            ReadLn(recFile,str);
            if Pos('end;',str)<>0 then break;
            pos2 := Pos('//',str);
            if pos2<>0 then
            begin
              ofs := Copy(str,pos2 + 2, Length(str));
              pos1 := Pos(':',str);
              if pos1<>0 then
              begin
                _name := Copy(str,1, pos1 - 1);
                _type := Copy(str,pos1 + 1, pos2 - pos1 - 1);
                recN.procInfo.AddLocal(StrToInt('$' + ofs) + recofs, 1, fname + '.' + _name, _type);
              end;
            End;
          end;
        end;
      end;
      CloseFile(recFile);
    End;
    while True do
    begin
      //KB
      _uses := KBase.GetTypeUses(PAnsiChar(ftype));
      pos1 := KBase.GetTypeIdxByModuleIds(_uses, PAnsiChar(ftype));
      _uses:=Nil;
      if pos1 = -1 then break;

      pos1 := KBase.TypeOffsets[pos1].NamId;
      if KBase.GetTypeInfo(pos1, [INFO_FIELDS], tInfo) then
      begin
        if tInfo.FieldsNum<>0 then
        begin
          p := tInfo.Fields;
          for pos2:=0 to tInfo.FieldsNum-1 do
          begin
            //Scope
            Inc(p);
            elofs := PInteger(p)^;
            Inc(p, 4);
            Inc(p, 4);//case
            //Name
            len1 := PWord(p)^;
            Inc(p, 2);
            _name := MakeString(p, len1);
            Inc(p, len1 + 1);
            //Type
            len1 := PWord(p)^;
            Inc(p, 2);
            _type := TrimTypeName(MakeString(p, len1));
            Inc(p, len1 + 1);
            recN.procInfo.AddLocal(recofs + elofs, 1, fname + '.' + _name, _type);
          end;
          break;
        end;
        if tInfo.Decl <> '' then ftype := tInfo.Decl;
      end;
    end;
  end;
  }
  FillVars;

  pnlVars.Visible := false;
  lbVars.Enabled := true;
  lbArgs.Enabled := true;

  bEdit.Enabled := true;
  bAdd.Enabled := false;
  bRemoveSelected.Enabled := false;
  bRemoveAll.Enabled := false;
  bOk.Enabled := true;
  VarModified := true;
end;

procedure TFEditFunctionDlg.bCancelVarClick(Sender : TObject);
begin
  pnlVars.Visible := false;
  lbVars.Enabled := true;
  lbArgs.Enabled := true;
  bOk.Enabled := false;
  VarModified := false;
end;

procedure TFEditFunctionDlg.bRemoveSelectedClick(Sender : TObject);
var
  recN:InfoRec;
  locInfo:PLocalInfo;
  n:Integer;
begin
  if pc.ActivePage = tsVars then
  begin
    recN := GetInfoRec(Adr);
    for n:=lbVars.Count-1 downto 0 do
      if lbVars.Selected[n] Then
      begin
        locInfo:=recN.procInfo.locals[n];
        recN.procInfo.DeleteLocal(n);
      end;
    FillVars;
    bEdit.Enabled := false;
    bRemoveSelected.Enabled := false;
    bRemoveAll.Enabled:=(lbVars.Count > 0);
  end;
end;

procedure TFEditFunctionDlg.bAddClick(Sender : TObject);
begin
  //String line, item;
  if pc.ActivePage = tsVars then
  Begin

  end;
end;

Procedure TFEditFunctionDlg.FillVMTCandidates;
var
  m:Integer;
  recV:PVmtListRec;
Begin
  if VmtCandidatesNum=0 then
  begin
    for m := 0 To VmtList.Count-1 do
    begin
      recV := VmtList.Items[m];
      cbVmtCandidates.Items.Add(recV.vmtName);
      Inc(VmtCandidatesNum);
    End;
    cbMethod.Visible := (VmtCandidatesNum <> 0);
    cbVmtCandidates.Visible := (VmtCandidatesNum <> 0);
  End;
end;

Procedure TFEditFunctionDlg.FillType;
Var
  argsBytes:Integer;
  flags:TProcFlagSet;
  recN:InfoRec;
  line:AnsiString;
Begin
  mType.Clear;
  recN := GetInfoRec(Adr);
  Case recN.kind of
    ikConstructor: rgFunctionKind.ItemIndex := 0;
    ikDestructor:  rgFunctionKind.ItemIndex := 1;
    ikProc:        rgFunctionKind.ItemIndex := 2;
    ikFunc:        rgFunctionKind.ItemIndex := 3;
  end;
  flags := recN.procInfo.flags;
  rgCallKind.ItemIndex := recN.procInfo.call_kind;
  cbEmbedded.Checked := PF_EMBED in flags;
  if cbMethod.Checked then
    line := recN.MakeMultilinePrototype(Adr, argsBytes, cbVmtCandidates.Text)
  Else line := recN.MakeMultilinePrototype(Adr, argsBytes, '');
  mType.Lines.Add(line);
  //No VMT - nothing to choose
  if VmtCandidatesNum=0 then
  begin
    cbMethod.Checked := false;
    cbMethod.Visible := false;
    cbVmtCandidates.Visible := false;
  end
  else
  begin
    if VmtCandidatesNum = 1 then cbVmtCandidates.Text := cbVmtCandidates.Items[0];
    if (recN.kind in [ikConstructor, ikDestructor]) or (PF_METHOD in flags) then
    begin
      cbMethod.Checked := true;
      if recN.HasName Then cbVmtCandidates.Text := ExtractClassName(recN.Name);
    End
    else cbMethod.Checked := false;
    cbMethod.Visible := true;
    cbVmtCandidates.Visible := true;
  End;
  recN.procInfo.flags:= recN.procInfo.flags - [PF_ARGSIZEL, PF_ARGSIZEG];
  if argsBytes > recN.procInfo.retBytes then Include(recN.procInfo.flags, PF_ARGSIZEG);
  if argsBytes < recN.procInfo.retBytes then Include(recN.procInfo.flags, PF_ARGSIZEL);

  lRetBytes.Caption := {'RetBytes: ' +} IntToStr(recN.procInfo.retBytes);
  lArgsBytes.Caption := {'ArgBytes: ' +} IntToStr(argsBytes);
end;

Procedure TFEditFunctionDlg.FillArgs;
var
  callKind:Byte;
  n, cnt, wid, maxwid, offset:Integer;
  canva:TCanvas;
  recN:InfoRec;
  argInfo:PARGINFO;
  line:AnsiString;
Begin
  lbArgs.Clear;
  recN := GetInfoRec(Adr);
  if Assigned(recN.procInfo.args) then
  begin
    canva := lbArgs.Canvas;
    maxwid := 0;
    cnt := recN.procInfo.args.Count;
    callKind := recN.procInfo.call_kind;
    if (callKind = 1) or (callKind = 3) then //cdecl, stdcall
    begin
      for n := 0 to cnt-1 do
      begin
        argInfo := recN.procInfo.args.Items[n];
        line := Val2Str(argInfo.Ndx,4) + ' ' + Val2Str(argInfo.Size,2) + ' ';
        if argInfo.Name <> '' then line:=line + argInfo.Name
          else line:=line + '?';
        line:=line + ':';
        if argInfo.TypeDef <> '' Then line:=line + argInfo.TypeDef
          else line:=line + '?';
        wid := canva.TextWidth(line);
        if wid > maxwid then maxwid := wid;
        lbArgs.Items.Add(line);
      End;
    end
    else if (callKind = 2) Then //pascal
    begin
      for n := cnt - 1 Downto 0 do
      begin
        argInfo := recN.procInfo.args.Items[n];
        line := Val2Str(argInfo.Ndx,4) + ' ' + Val2Str(argInfo.Size,2) + ' ';
        if argInfo.Name <> '' then line:=line + argInfo.Name
          else line:=line + '?';
        line:=line + ':';
        if argInfo.TypeDef <> '' then line:=line + argInfo.TypeDef
          else line:=line + '?';
        wid := canva.TextWidth(line);
        if wid > maxwid then maxwid := wid;
        lbArgs.Items.Add(line);
      End;
    end
    else //fastcall, safecall
    begin
      offset := recN.procInfo.bpBase;
      for n := 0 to cnt-1 do
      begin
        argInfo := recN.procInfo.args.Items[n];
        if argInfo.Ndx > 2 then
        begin
          Inc(offset, argInfo.Size);
          continue;
        end;
        if argInfo.Ndx = 0 then line := ' eax '
        else if argInfo.Ndx = 1 then line := ' edx '
        else if argInfo.Ndx = 2 then line := ' ecx ';
        line:=line + Val2Str(argInfo.Size,2) + ' ';
        if argInfo.Tag = $22 then line:=line + 'var ';
        if argInfo.Name <> '' then line:=line + argInfo.Name
          else line:=line + '?';
        line:=line + ':';
        if argInfo.TypeDef <> '' then line:=line + argInfo.TypeDef
          else line:=line + '?';
        wid := canva.TextWidth(line);
        if wid > maxwid then maxwid := wid;
        lbArgs.Items.Add(line);
      end;
      for n := 0 to cnt-1 do
      begin
        argInfo := recN.procInfo.args.Items[n];
        if argInfo.Ndx <= 2 then continue;
        Dec(offset, argInfo.Size);
        line := Val2Str(offset,4) + ' ' + Val2Str(argInfo.Size,2) + ' ';
        if argInfo.Tag = $22 then line:=line + 'var ';
        if argInfo.Name <> '' then line:=line + argInfo.Name
          else line:=line + '?';
        line:=line + ':';
        if argInfo.TypeDef <> '' then line:=line + argInfo.TypeDef
          else line:=line + '?';
        wid := canva.TextWidth(line);
        if wid > maxwid then maxwid := wid;
        lbArgs.Items.Add(line);
      end;
    End;
    lbArgs.ScrollWidth := maxwid + 2;
  End;
end;

Procedure TFEditFunctionDlg.FillVars;
Var
  n, cnt, wid, maxwid:Integer;
  canva:TCanvas;
  recN:InfoRec;
  locInfo:PLocalInfo;
  line:AnsiString;
Begin
  lbVars.Clear;
  rgLocBase.ItemIndex := -1;
  recN := GetInfoRec(Adr);
  if Assigned(recN.procInfo.locals) then
  begin
    rgLocBase.ItemIndex := Ord(PF_BPBASED in recN.procInfo.flags);
    canva := lbVars.Canvas;
    maxwid := 0;
    cnt := recN.procInfo.locals.Count;
    for n := 0 to cnt-1 do
    begin
      locInfo := recN.procInfo.locals.Items[n];
      line := Val2Str(-locInfo.Ofs,8) + ' ' + Val2Str(locInfo.Size,2) + ' ';
      if locInfo.Name <> '' then line:=line + locInfo.Name
        else line:=line + '?';
      line:=line + ':';
      if locInfo.TypeDef <> '' then line:=line + locInfo.TypeDef
        else line:=line + '?';
      wid := canva.TextWidth(line);
      if wid > maxwid then maxwid := wid;
      lbVars.Items.Add(line);
    End;
    lbVars.ScrollWidth := maxwid + 2;
  End;
end;

procedure TFEditFunctionDlg.FormClose(Sender : TObject; var Action:TCloseAction);
Var
  recN:InfoRec;
begin
  if not TypModified then
  begin
    recN := GetInfoRec(Adr);
    recN.SetName(SName);
    recN.procInfo.flags := SFlags;
  end
  else ProjectModified := true;
end;

procedure TFEditFunctionDlg.cbMethodClick(Sender : TObject);
Var
  recN:InfoRec;
begin
  recN := GetInfoRec(Adr);
  if cbMethod.Checked then
  begin
    cbVmtCandidates.Enabled := true;
    Include(recN.procInfo.flags, PF_METHOD);
    FillType;
    cbVmtCandidates.Text := PArgInfo(recN.procInfo.args.Items[0]).TypeDef;
  end
  else
  begin
    cbVmtCandidates.Enabled := false;
    Exclude(recN.procInfo.flags, PF_METHOD);
    FillType;
    cbVmtCandidates.Text := '';
  End;
end;

procedure TFEditFunctionDlg.bRemoveAllClick(Sender: TObject);
var
  recN:InfoRec;
begin
  recN:=GetInfoRec(Adr);
  If Assigned(recN.procInfo.locals) Then
  Begin
    recN.procInfo.DeleteLocals;
    FillVars;
    bEdit.Enabled:=False;
    bRemoveSelected.Enabled:=False;
    bRemoveAll.Enabled:=false;
  end;
end;

end.
