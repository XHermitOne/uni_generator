{
Функции взаимодействия с операционной системой

Версия: 0.0.2.2
}
unit sysfunc;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF windows}
  Windows,
  {$ENDIF}
  Classes,
  Process,
  SysUtils;

{$IFDEF linux}
{ some linux-specific code }
const OS: AnsiString = 'linux';
{$ENDIF}

{$IFDEF windows}
{ some M$-specific code }
const OS: AnsiString = 'windows';
{$ENDIF}

{ Тип операционной системы: linux/windows}
function GetOSType(): AnsiString;

{ Проверка является ли ОС Linux }
function IsOSLinux(): Boolean;

{ Проверка является ли ОС Windows }
function IsOSWindows(): Boolean;

{ Наименование компьютера }
function GetNetComputerName(): AnsiString;

{ 
Запуск комманды ОС 
}
procedure ExecuteSystem(Command: AnsiString);

implementation

uses
  fileutil,
  log,
  strfunc;

{
Тип операционной системы: linux/windows
}
function GetOSType(): AnsiString;
begin
  Result := OS;
end;

{ Проверка является ли ОС Linux }
function IsOSLinux(): Boolean;
begin
  Result := OS = 'linux';
end;

{ Проверка является ли ОС Windows }
function IsOSWindows(): Boolean;
begin
  Result := OS = 'windows';
end;

{ Наименование компьютера }
function GetNetComputerName(): AnsiString;
{$IFDEF windows}
var
  buffer: Array[0..255] Of char;
  size: dword;
{$ENDIF}

begin
  Result := '';

  {$IFDEF windows}
  size := 256;
  if GetComputerName(buffer, size) then
    Result := buffer;
  {$ENDIF}
end;

{ 
Запуск комманды ОС 
}
procedure ExecuteSystem(Command: AnsiString);
var
  cmd: Array Of String;
  i: Integer;

begin
  cmd := strfunc.SplitStr(Command, ' ');
  with TProcess.Create(nil) do
  try
    Executable := fileutil.FindDefaultExecutablePath(cmd[0]);
    log.DebugMsgFmt('Программа <%s>', [Executable]);
    for i := 1 to Length(cmd) - 1 do
    begin
      Parameters.Add(Trim(cmd[i]));
      log.DebugMsgFmt('%d. Параметры коммандной строки <%s>', [i, Trim(cmd[i])]);
    end;
    Execute;
  finally
    Free;
  end;
end;

end.

