{
Консольный режим работы программы UniLogger.
Этот вид запуска предназначен для вызова в шедулере по расписанию.

Версия 0.0.1.1

@bold(Поиск утечек памяти)

Включение поиска утечек:
Меню Lazarus -> Проект -> Параметры проекта... ->
Параметры проекта -> Отладка -> Выставить галки для ключей -gl и -gh

Вывод делаем в текстовый файл *.mem в:

@longcode(#
***********************************************************
if UseHeapTrace then     // Test if reporting is on
   SetHeapTraceOutput(ChangeFileExt(ParamStr(0), '.mem'));
***********************************************************
#)

Допустим, имеем код, который заведомо без утечек:

@longcode(#
***********************************************************
uses heaptrc;
var
  p1, p2, p3: pointer;

begin
  getmem(p1, 100);
  getmem(p2, 200);
  getmem(p3, 300);

  // ...

  freemem(p3);
  freemem(p2);
  freemem(p1);
end.
***********************************************************
#)

, после запуска и завершения работы программы, в консоли наблюдаем отчет:

@longcode(#
***********************************************************
Running "f:\programs\pascal\tst.exe "
Heap dump by heaptrc unit
3 memory blocks allocated : 600/608
3 memory blocks freed     : 600/608
0 unfreed memory blocks : 0
True heap size : 163840 (80 used in System startup)
True free heap : 163760
***********************************************************
#)

Утечек нет, раз "0 unfreed memory blocks"
Теперь внесем утечку, "забудем" вернуть память выделенную под p2:

@longcode(#
***********************************************************
uses heaptrc;
var
  p1, p2, p3: pointer;

begin
  getmem(p1, 100);
  getmem(p2, 200);
  getmem(p3, 300);

  // ...

  freemem(p3);
  // freemem(p2);
  freemem(p1);
end.
***********************************************************
#)

и смотрим на результат:

@longcode(#
***********************************************************
Running "f:\programs\pascal\tst.exe "
Heap dump by heaptrc unit
3 memory blocks allocated : 600/608
2 memory blocks freed     : 400/408
1 unfreed memory blocks : 200
True heap size : 163840 (80 used in System startup)
True free heap : 163488
Should be : 163496
Call trace for block $0005D210 size 200
  $00408231
***********************************************************
#)

200 байт - утечка...
Если будешь компилировать еще и с ключом -gl,
то ко всему прочему получишь и место, где была выделена "утекающая" память.

ВНИМАНИЕ! Если происходят утечки памяти в модулях Indy
необходимо в C:\lazarus\fpc\3.0.4\source\packages\indy\IdCompilerDefines.inc
добавить @code($DEFINE IDFREEONFINAL) в секции FPC (2+)
и перекомпилировать проект.
}

program uni_generator;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  {
  ПРИМЕЧАНИЕ: Если при компиляции проект не находит компоненты
              Ошибка компиляции:
              Error: Undefined symbol: WSRegisterCustomImageList ... и т.п.
              то необходимо в секцию uses необходимо добавить модуль Interfaces
  }
  Interfaces,
  Classes, SysUtils, CustApp,
  { you can add units after this }
  memfunc,
  engine, log, settings;

type

  { TUniGeneratorApplication }

  TUniGeneratorApplication = class(TCustomApplication)
  protected
    procedure DoRun; override;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;

    procedure WriteHelp; virtual;
    procedure WriteVersion; virtual;
  end;

{ TUniGeneratorApplication }

procedure TUniGeneratorApplication.DoRun;
var
  ErrorMsg: String;
begin
  // Чтание параметров коммандной строки
  ErrorMsg := CheckOptions('hvdls:', 'help version debug log settings:');
  if ErrorMsg <> '' then
  begin
    ShowException(Exception.Create(ErrorMsg));
    Terminate;
    Exit;
  end;

  // parse parameters
  if HasOption('h', 'help') then
  begin
    WriteHelp;
    Terminate;
    Exit;
  end;

  if HasOption('v', 'version') then
  begin
    WriteVersion;
    Terminate;
    Exit;
  end;

  if HasOption('d', 'debug') then
    DEBUG_MODE := True;

  if HasOption('l', 'log') then
    LOG_MODE := True;

  if HasOption('s', 'settings') then
    settings.SETTINGS_INI_FILENAME := Trim(GetOptionValue('s', 'settings'));

  if LOG_MODE then
    OpenLog(ChangeFileExt(ParamStr(0), '.log'));

  { add your program here }
  // Инициализируем объект движка и всех его внутренних объектов
  engine.GENERATOR_ENGINE := TICGenerator.Create(nil);
  engine.GENERATOR_ENGINE.Start;

  // Выполнить обработчик одного тика
  if (engine.GENERATOR_ENGINE <> nil) then
    engine.GENERATOR_ENGINE.Tick;

  // Корректно завершаем работу движка
  engine.GENERATOR_ENGINE.Stop;
  engine.GENERATOR_ENGINE.Destroy;
  engine.GENERATOR_ENGINE := nil;

  // stop program loop
  Terminate;
end;

constructor TUniGeneratorApplication.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  StopOnException := True;
end;

destructor TUniGeneratorApplication.Destroy;
begin
  inherited Destroy;
end;

procedure TUniGeneratorApplication.WriteHelp;
begin
  { add your help code here }
  PrintColorTxt('uni_generator - Программа генерации текстовых файлов из различных источников данных', CYAN_COLOR_TEXT);
  PrintColorTxt(Format('Версия: %s', [engine.VERSION]), CYAN_COLOR_TEXT);
  PrintColorTxt('Парметры коммандной строки:', CYAN_COLOR_TEXT);
  PrintColorTxt(Format('    Помощь: %s --help', [ExeName]), CYAN_COLOR_TEXT);
  PrintColorTxt(Format('    Версия программы: %s --version', [ExeName]), CYAN_COLOR_TEXT);
  PrintColorTxt(Format('    Режим вывода сообщений в консоль: %s --debug', [ExeName]), CYAN_COLOR_TEXT);
  PrintColorTxt(Format('    Режим вывода сообщений в журнал: %s --log', [ExeName]), CYAN_COLOR_TEXT);
  PrintColorTxt(Format('    Файл настройки: %s --settings=имя_файла_настройки.ini', [ExeName]), CYAN_COLOR_TEXT);
end;

procedure TUniGeneratorApplication.WriteVersion;
begin
  PrintColorTxt(Format('uni_generator. Версия: %s', [engine.VERSION]), CYAN_COLOR_TEXT);
end;

var
  Application: TUniGeneratorApplication;

{$R *.res}

begin
  Application:=TUniGeneratorApplication.Create(nil);
  Application.Title:='UniGenerator';
  Application.Run;
  Application.Free;

  // Учет утечек памяти. Вывод делаем в текстовый файл *.mem
  {$if declared(UseHeapTrace)}
  if UseHeapTrace then // Test if reporting is on
     SetHeapTraceOutput(ChangeFileExt(ParamStr(0), '.mem'));
  {$ifend}
end.

