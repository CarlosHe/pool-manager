unit PoolManager.Item;

interface

uses
  System.SysUtils,
  System.SyncObjs,
  PoolManager.Contract.Item;

type

  TPoolItem<T: class> = class(TInterfacedObject, IPoolItem<T>)
  strict private
    constructor Create(const AItem: T);
  private
    FItem: T;
    FIdleTime: TDateTime;
    FRefCount: UInt64;
  public
    destructor Destroy; override;
    function GetRefCount: UInt64;
    function IsIdle(out AIdleTime: TDateTime): Boolean;
    function Acquire: T;
    procedure Release;
    function GetItem: T;
    class function New(const AItem: T): IPoolItem<T>;
  end;

implementation

{ TPoolItem<T> }

constructor TPoolItem<T>.Create(const AItem: T);
begin
  FItem := AItem;
  FRefCount := 0;
  FIdleTime := Now;
end;

destructor TPoolItem<T>.Destroy;
begin
  inherited;
end;

function TPoolItem<T>.Acquire: T;
begin
  TInterlocked.Increment(FRefCount);
  FIdleTime := 0;
  Result := FItem;
end;

procedure TPoolItem<T>.Release;
var
  Count: UInt64;
begin
  Count := TInterlocked.Decrement(FRefCount);
  if Count = 0 then
    FIdleTime := Now;
end;

function TPoolItem<T>.GetItem: T;
begin
  Result := FItem;
end;

function TPoolItem<T>.GetRefCount: UInt64;
begin
  Result := TInterlocked.Read(FRefCount);
end;

function TPoolItem<T>.IsIdle(out AIdleTime: TDateTime): Boolean;
begin
  Result := TInterlocked.Read(FRefCount) = 0;
  if Result then
    AIdleTime := FIdleTime
  else
    AIdleTime := 0;
end;

class function TPoolItem<T>.New(const AItem: T): IPoolItem<T>;
begin
  Result := Self.Create(AItem);
end;

end.

