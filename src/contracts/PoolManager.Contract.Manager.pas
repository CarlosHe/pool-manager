unit PoolManager.Contract.Manager;

interface

uses
  PoolManager.Contract.Item;

type

  IPoolManager<T: class> = interface
    ['{18E4165C-2D4F-481E-BB54-496C250EBBEA}']
    procedure DoCreateInstance(var AInstance: T);
    procedure DoDestroyInstance(AInstance: T);
    procedure SetMaxRefCountPerItem(AMaxRefCountPerItem: UInt64);
    procedure SetMaxIdleSeconds(AMaxIdleSeconds: UInt64);
    procedure SetMinPoolCount(AMinPoolCount: UInt64);
    function TryAcquireItem(out APoolItem: IPoolItem<T>): Boolean;
  end;

implementation

end.
