unit PoolManager.Contract.Item;

interface

type

   IPoolItem<T: class> = interface
      ['{70ABC946-15D5-495C-A345-7CCC7D9DC75C}']
      function GetRefCount: UInt64;
      function IsIdle(out AIdleTime: TDateTime): Boolean;
      function Acquire: T;
      procedure Release;
      function GetItem: T;
   end;

implementation

end.
