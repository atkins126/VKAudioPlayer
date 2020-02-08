unit BassPlayer.LoadHandle;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, Vcl.Forms, System.Variants, System.Classes,
  System.Generics.Collections;

type
  TLoadThread = class
  private
    FBefore: TProc;
    FAsync: TFunc<TLoadThread, Boolean>;
    FAfter: TProc<Boolean>;
    FDoStopThread: Boolean;
    FWorking: Boolean;
  protected
    procedure FProc;
  public
    procedure Execute;
    procedure Stop; virtual;
    procedure Await(AppProc: Boolean = True);
    property IsWorking: Boolean read FWorking;
    property NeedStop: Boolean read FDoStopThread;
    constructor Create(Before: TProc; Async: TFunc<TLoadThread, Boolean>; After: TProc<Boolean>);
  end;

  TLoadPlaylist = class(TLoadThread)
  private
    FAsync: TFunc<TLoadThread, Integer, Integer, Boolean>;
    procedure FProc(OwnerId, Id: Integer);
  public
    procedure Execute(OwnerId, Id: Integer);
    constructor Create(Before: TProc; Async: TFunc<TLoadThread, Integer, Integer, Boolean>; After: TProc<Boolean>);
  end;

  TLoadSearch = class(TLoadThread)
  private
    FAsync: TFunc<TLoadThread, string, Boolean>;
    procedure FProc(Query: string);
  public
    procedure Execute(Query: string);
    constructor Create(Before: TProc; Async: TFunc<TLoadThread, string, Boolean>; After: TProc<Boolean>);
  end;

  TLoaders = class(TList<TLoadThread>)
    procedure Stop;
    procedure Await;
    procedure Clear;
  end;

implementation

procedure TLoadThread.Await;
begin
  while FWorking do
    if AppProc then
      Application.ProcessMessages;
end;

constructor TLoadThread.Create(Before: TProc; Async: TFunc<TLoadThread, Boolean>; After: TProc<Boolean>);
begin
  FBefore := Before;
  FAsync := Async;
  FAfter := After;
  FWorking := False;
  FDoStopThread := False;
end;

procedure TLoadThread.Execute;
begin
  FProc;
end;

procedure TLoadThread.FProc;
begin
  if Assigned(FBefore) then
    FBefore;
  TThread.CreateAnonymousThread(
    procedure
    var
      DoAfter: Boolean;
    begin
      FDoStopThread := True;
      while FWorking do
        Sleep(100);
      FDoStopThread := False;
      FWorking := True;
      try
        DoAfter := FAsync(Self);
        if Assigned(FAfter) then
        begin
          FAfter(DoAfter and (not FDoStopThread));
        end;
      except
      end;
      FWorking := False;
    end).Start;
end;

procedure TLoadThread.Stop;
begin
  FDoStopThread := True;
end;

{ TLoadPlaylist }

constructor TLoadPlaylist.Create(Before: TProc; Async: TFunc<TLoadThread, Integer, Integer, Boolean>;
  After: TProc<Boolean>);
begin
  FBefore := Before;
  FAsync := Async;
  FAfter := After;
  FWorking := False;
  FDoStopThread := False;
end;

procedure TLoadPlaylist.Execute(OwnerId, Id: Integer);
begin
  FProc(OwnerId, Id);
end;

procedure TLoadPlaylist.FProc(OwnerId, Id: Integer);
begin
  if Assigned(FBefore) then
    FBefore;
  TThread.CreateAnonymousThread(
    procedure
    var
      DoAfter: Boolean;
    begin
      FDoStopThread := True;
      while FWorking do
        Sleep(100);
      FDoStopThread := False;
      FWorking := True;
      try
        DoAfter := FAsync(Self, OwnerId, Id);
        if Assigned(FAfter) then
        begin
          FAfter((not FDoStopThread) and DoAfter);
        end;
      except
      end;
      FWorking := False;
    end).Start;
end;

{ TLoaders }

procedure TLoaders.Await;
var
  i: Integer;
  FComplete: Boolean;
begin
  repeat
    FComplete := True;
    for i := 0 to Count - 1 do
    begin
      if Items[i].IsWorking then
        FComplete := False;
    end;
    if not FComplete then
      Application.ProcessMessages;
  until FComplete;
end;

procedure TLoaders.Clear;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Free;
  inherited;
end;

procedure TLoaders.Stop;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    Items[i].Stop;
end;

{ TLoadSearch }

constructor TLoadSearch.Create(Before: TProc; Async: TFunc<TLoadThread, string, Boolean>; After: TProc<Boolean>);
begin
  FBefore := Before;
  FAsync := Async;
  FAfter := After;
  FWorking := False;
  FDoStopThread := False;
end;

procedure TLoadSearch.Execute(Query: string);
begin
  FProc(Query);
end;

procedure TLoadSearch.FProc(Query: string);
begin
  if Assigned(FBefore) then
    FBefore;
  TThread.CreateAnonymousThread(
    procedure
    var
      DoAfter: Boolean;
    begin
      FDoStopThread := True;
      while FWorking do
        Sleep(100);
      FDoStopThread := False;
      FWorking := True;
      try
        DoAfter := FAsync(Self, Query);
        if Assigned(FAfter) then
        begin
          FAfter((not FDoStopThread) and DoAfter);
        end;
      except
      end;
      FWorking := False;
    end).Start;
end;

end.

