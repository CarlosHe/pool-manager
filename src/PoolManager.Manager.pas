unit PoolManager.Manager;

interface

uses
  System.Classes,
  System.SyncObjs,
  System.Generics.Collections,
  PoolManager.Contract.Manager,
  PoolManager.Contract.Item;

type

  TPoolManager<T: class> = class(TInterfacedObject, IPoolManager<T>)
  private
    FMonitor: TThread;
    FIsRunning: Boolean;
    FEvent: TEvent;
    FPoolItemList: TList<IPoolItem<T>>;
    FLock: TCriticalSection;
    FMaxRefCountPerItem: UInt64;
    FMaxIdleSeconds: UInt64;
    FMinPoolCount: UInt64;
    procedure DoMonitor;
    procedure DoReleaseItems;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure DoCreateInstance(var AInstance: T); virtual; abstract;
    procedure DoDestroyInstance(AInstance: T); virtual; abstract;
    procedure SetMaxRefCountPerItem(AMaxRefCountPerItem: UInt64);
    procedure SetMaxIdleSeconds(AMaxIdleSeconds: UInt64);
    procedure SetMinPoolCount(AMinPoolCount: UInt64);
    function TryAcquireItem(out APoolItem: IPoolItem<T>): Boolean;
  end;

implementation

uses
  System.SysUtils,
  System.DateUtils,
  PoolManager.Item;

{ TPoolManager<T> }

constructor TPoolManager<T>.Create;
begin
  inherited;
  FIsRunning := True;
  FMinPoolCount := 0;
  FMaxRefCountPerItem := 1;
  FMaxIdleSeconds := 60;
  FLock := TCriticalSection.Create;
  FPoolItemList := TList < IPoolItem < T >>.Create;
  FEvent := TEvent.Create;

  FMonitor := TThread.CreateAnonymousThread(DoMonitor);
  FMonitor.FreeOnTerminate := False;
  FMonitor.Start;
end;

destructor TPoolManager<T>.Destroy;
begin
  FIsRunning := False;
  FEvent.SetEvent;
  FMonitor.WaitFor;
  FMonitor.Free;

  FLock.Enter;
  try
    for var LPoolItem in FPoolItemList do
    begin
      try
        var
        LItem := LPoolItem.GetItem;
        DoDestroyInstance(LItem);
      except
      end;
    end;
    FPoolItemList.Free;
  finally
    FLock.Leave;
    FLock.Free;
  end;

  FEvent.Free;
  inherited;
end;

procedure TPoolManager<T>.DoMonitor;
begin
  while FIsRunning do
  begin
    try
      if FEvent.WaitFor(1000) = wrTimeout then
        DoReleaseItems;
    except
    end;
    FEvent.ResetEvent;
  end;
end;

procedure TPoolManager<T>.DoReleaseItems;
var
  LIdleTime: TDateTime;
begin
  FLock.Enter;
  try
    for var I := Pred(FPoolItemList.Count) downto 0 do
    begin
      if FPoolItemList[I].IsIdle(LIdleTime) and
        (FPoolItemList.Count > FMinPoolCount) and
        (SecondsBetween(Now, LIdleTime) >= FMaxIdleSeconds) then
      begin
        var
        LItem := FPoolItemList[I].GetItem;
        try
          DoDestroyInstance(LItem);
        finally
          FPoolItemList.Delete(I);
        end;
      end;
    end;
  finally
    FLock.Leave;
  end;
end;

function TPoolManager<T>.TryAcquireItem(out APoolItem: IPoolItem<T>): Boolean;
begin
  FLock.Enter;
  try
    for var LPoolItem in FPoolItemList do
    begin
      if LPoolItem.GetRefCount < FMaxRefCountPerItem then
      begin
        APoolItem := LPoolItem;
        APoolItem.Acquire;
        Exit(True);
      end;
    end;

    var LInstance: T := nil;
    DoCreateInstance(LInstance);
    if not Assigned(LInstance) then
      Exit(False);

    APoolItem := TPoolItem<T>.New(LInstance);
    APoolItem.Acquire;
    FPoolItemList.Add(APoolItem);
    Result := True;
  finally
    FLock.Leave;
  end;
end;

procedure TPoolManager<T>.SetMaxIdleSeconds(AMaxIdleSeconds: UInt64);
begin
  FMaxIdleSeconds := AMaxIdleSeconds;
end;

procedure TPoolManager<T>.SetMaxRefCountPerItem(AMaxRefCountPerItem: UInt64);
begin
  FMaxRefCountPerItem := AMaxRefCountPerItem;
end;

procedure TPoolManager<T>.SetMinPoolCount(AMinPoolCount: UInt64);
begin
  FMinPoolCount := AMinPoolCount;
end;

end.
