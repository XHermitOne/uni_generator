{
Функции работы с файлами.

Версия: 0.0.3.1
}
unit filefunc;

{$mode objfpc}{$H+}

interface

uses
  {$IFDEF windows}
  Windows,
  {$ENDIF}
  Classes, SysUtils,
  sysfunc, strfunc, exttypes;

{ Определить папку домашней директории }
function GetHomeDir(): AnsiString;

{ Домашняя папка в Linux системах }
function GetOSLinuxHomeDir(): AnsiString;
{ Домашняя папка в Windows системах }
function GetOSWindowsHomeDir(): AnsiString;

{ Функция соединяет пути с учётом особенностей операционной системы }
function JoinPath(PathParts: Array Of String): AnsiString;

{ Функция разделяет путь на составляющие }
function SplitPath(sPath: AnsiString): TArrayOfString;

{ Создать весь путь папки }
function CreateDirPath(sPath: AnsiString): Boolean;
{ Создать весь путь папки. Путь должен быть нормализован. }
function CreateDirPathTree(sPath: AnsiString): Boolean;

{ Создать пустой файл }
function CreateEmptyFile(sPath: AnsiString): Boolean;

{ Создать пустой файл если он не существует }
function CreateEmptyFileIfNotExists(sPath: AnsiString): Boolean;

{ Нормализовать путь до файла }
function NormalPathFileName(sPath: AnsiString): AnsiString;

{
Чтение текстового файла как строки
@param sTxtFileName: Полное имя текстового файла.
@return: Текст, содержащийся внутри файла в виде строки
или пустая строка в случае ошибки.
}
function ReadTxtFile(sTxtFileName: AnsiString): AnsiString;

{ Преобразование Даты-времени }
{$IFDEF windows}
function DateTimeToFileTime(dtFileTime: TDateTime): TFileTime;
{$ENDIF}

{$IFDEF windows}
function FileTimeToDateTime(const ftFileTime: TFileTime): TDateTime;
{$ENDIF}

{
Удаление файла
@param sFileName: Полное имя удаляемого файла.
@return: Результат удаления True/False.
}
function DelFile(sFileName: AnsiString): Boolean;

{
Получить дату-время создания файла.
@param sFileName: Полное имя файла.
@return: Дата-время создания файла.
}
function GetCreateFileDateTime(sFileName: AnsiString): TDateTime;


implementation

uses
  log;

{
Определить папку домашней директории
}
function GetHomeDir(): AnsiString;
begin
  Result := '';
  if IsOSLinux() then
    Result := GetOSLinuxHomeDir()
  else if IsOSWindows() then
    Result := GetOSWindowsHomeDir()
  else
    log.WarningMsgFmt('Не поддерживаемая ОС <%s>', [GetOSType()]);
end;

{
Домашняя папка в Linux системах.
}
function GetOSLinuxHomeDir(): AnsiString;
begin
  Result := '';
  {$IFDEF linux}
  Result := GetEnvironmentVariable('HOME');
  {$ENDIF}
end;

{
Домашняя папка в Windows системах.
}
function GetOSWindowsHomeDir(): AnsiString;
begin
  Result := '';
  {$IFDEF windows}
  Result := GetAppConfigDir(False);
  {$ENDIF}
end;

{
Функция соединяет пути с учётом особенностей операционной системы.
}
function JoinPath(PathParts: Array Of String): AnsiString;
begin
  Result := JoinStr(PathParts, PathDelim);
end;

{
Функция разделяет путь на составляющие.
}
function SplitPath(sPath: AnsiString): TArrayOfString;
begin
  Result := SplitStr(sPath, PathDelim);
end;


{
Создать весь путь папки
}
function CreateDirPath(sPath: AnsiString): Boolean;
begin
  Result := False;

  // Нормализация пути
  sPath := NormalPathFileName(sPath);

  if not DirectoryExists(sPath) then
  begin
     log.InfoMsgFmt('Создание папки <%s>', [sPath]);
     Result := CreateDirPathTree(sPath);
  end;
end;

{
Создать весь путь папки. Путь должен быть нормализован.
}
function CreateDirPathTree(sPath: AnsiString): Boolean;
var
  parent_path: AnsiString;
begin
  if not DirectoryExists(sPath) then
  begin
    parent_path := ExtractFileDir(sPath);
    if not DirectoryExists(parent_path) then
       Result := CreateDirPathTree(parent_path);
    CreateDir(sPath);
    Result := True;
    Exit;
  end;
  Result := False;
end;

{
Создать пустой файл.
}
function CreateEmptyFile(sPath: AnsiString): Boolean;
var
  file_tmp: Text;
begin
  // Нормализация пути
  sPath := NormalPathFileName(sPath);

  log.InfoMsgFmt('Создание пустого файла <%s>', [sPath]);
  AssignFile(file_tmp, sPath);
  try
    Rewrite(file_tmp);
    Writeln(file_tmp, '');   //Remember AnsiStrings are case sensitive
    CloseFile(file_tmp);
    Result := True;
  except
    Result := False;
    CloseFile(file_tmp);
  end;
end;

{
Создать пустой файл если он не существует.
}
function CreateEmptyFileIfNotExists(sPath: AnsiString): Boolean;
begin
  Result := False;
  if not FileExists(sPath) then
    Result := CreateEmptyFile(sPath)
end;

{
Нормализовать путь до файла.
}
function NormalPathFileName(sPath: AnsiString): AnsiString;
begin
  // Замена двойных слешей
  sPath := StringReplace(sPath, PathDelim + PathDelim, PathDelim, [rfReplaceAll]);
  Result := ExpandFileName(sPath);
end;

{
Чтение текстового файла как строки
@param sTxtFileName: Полное имя текстового файла.
@return: Текст, содержащийся внутри файла в виде строки
или пустая строка в случае ошибки.
}
function ReadTxtFile(sTxtFileName: AnsiString): AnsiString;
var
  txt_file: file of Char;
  symbol: Char;

begin
  Result := '';
  if sTxtFileName = '' then
  begin
    log.WarningMsg('Не определен текстовый файл');
    Exit;
  end;

  if not FileExists(sTxtFileName) then
  begin
    log.WarningMsgFmt('Текстовый файл <%s> не найден', [sTxtFileName]);
    Exit;
  end;

  try
    Assign (txt_file, sTxtFileName);
    Reset(txt_file);

    while not eof(txt_file) do
    begin
      Read(txt_file, symbol);
      Result := Result + symbol;
    end;

    Close(txt_file);
  except
    Close(txt_file);
    log.FatalMsgFmt('Ошибка чтения файла <%s>', [sTxtFileName]);
    Result := '';
  end;
end;

{$IFDEF windows}
{
Преобразование Даты-времени
}
function DateTimeToFileTime(dtFileTime: TDateTime): TFileTime;
var
  LocalFileTime: TFileTime;
  SystemTime: TSystemTime;
begin
  Result.dwLowDateTime  := 0;
  Result.dwHighDateTime := 0;
  DateTimeToSystemTime(dtFileTime, SystemTime);
  //log.DebugMsgFmt('System time: %d-%d-%d %d:%d:%d.%d', [SystemTime.Year, SystemTime.Month, SystemTime.Day,
  //                                                     SystemTime.Hour, SystemTime.Minute, SystemTime.Second, SystemTime.Millisecond]);
  SystemTimeToFileTime(SystemTime, LocalFileTime);
  //log.DebugMsgFmt('Local file time: %s', [FormatDateTime('YYYY-MM-DD HH:NN:SS', FileTimeToDateTime(LocalFileTime))]);
  // Перевод к времени по гринвичу:
  //LocalFileTimeToFileTime(LocalFileTime, Ft);
  //log.DebugMsgFmt('File time: %s', [FormatDateTime('YYYY-MM-DD HH:NN:SS', FileTimeToDateTime(Ft))]);
  Result := LocalFileTime;
end;
{$ENDIF}

{$IFDEF windows}
function FileTimeToDateTime(const ftFileTime: TFileTime): TDateTime;
const
  FileTimeBase = -109205.0;
  FileTimeStep: Extended = 24.0 * 60.0 * 60.0 * 1000.0 * 1000.0 * 10.0; // 100 nSek per Day
begin
  Result := Int64(ftFileTime) / FileTimeStep;
  Result := Result + FileTimeBase;
end;
{$ENDIF}

{
Удаление файла
@param sFileName: Полное имя удаляемого файла.
@return: Результат удаления True/False.
}
function DelFile(sFileName: AnsiString): Boolean;
begin
  try
    sFileName := NormalPathFileName(sFileName);
    if not FileExists(sFileName) then
    begin
      log.WarningMsgFmt('Удаление. Файл <%s> не найден', [sFileName]);
      Result := False;
      Exit;
    end;
    log.InfoMsgFmt('Удаление файла <%s>', [sFileName]);
    Result := DeleteFile(sFileName);
  except
    log.FatalMsgFmt('Ошибка удаления файла <%s>', [sFileName]);
    Result := False;
  end;
end;

{
Получить дату-время создания файла.
@param sFileName: Полное имя файла.
@return: Дата-время создания файла.
}
function GetCreateFileDateTime(sFileName: AnsiString): TDateTime;
var
  search_record: TSearchRec;
  UTCTime, LocalTime: TSystemTime;
  find_result: Boolean;

begin
  find_result := FindFirst(sFileName, faArchive, search_record) = 0;
  if find_result then
  begin
    SysUtils.FindClose(search_record);
    find_result := FileTimeToSystemTime(@search_record.FindData.ftCreationTime, @UTCTime) and
      SystemTimeToTzSpecificLocalTime(nil, @UTCTime, @LocalTime);
  end;
  if find_result then
    Result := SystemTimeToDateTime(LocalTime)
  else
    Result := 0;
end;

end.

