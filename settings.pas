{
Модуль поддержки настроек программы

Версия: 0.0.3.3
}
unit settings;

{$mode objfpc}{$H+}

interface

uses
  {INIFiles - модуль который содержит класс для работы с INI-файлами}
  Classes, SysUtils, INIFiles, StrUtils,
  inifunc, dictionary, strfunc, exttypes;

// const DEFAULT_SETTINGS_INI_FILENAME: AnsiString = 'settings.ini';

type
  {
  TICSettingsManager - Менеджер управления настройками программы
  }
  TICSettingsManager = class(TObject)
  private
    { Полное наименование INI файла }
    FIniFileName: AnsiString;
    { Содержимое INI файла в виде словаря словарей (разложено по секциям)}
    FContent: TIniDictionary;

  public

    constructor Create;
    destructor Destroy; override;

    {Генерация имени настроечного INI файла}
    function GenIniFileName(): AnsiString;
    { Вывод на экран текущих настроек для отладки. }
    procedure PrintSettings();
    {
    Загрузка параметров из INI файла
    @param sINIFileName Полное наименование INI Файла
    @return True/False
    }
    function LoadSettings(sINIFileName: AnsiString): Boolean;
    {
    Проверка существования файла настройки
    @param sINIFileName Полное наименование INI Файла
    @return True/False
    }
    function ExistsIniFile(sINIFileName: AnsiString): Boolean;
    {
    Собрать полное описание секции с учетом ключа parent
    @param sSectionName Наименование секции
    @return Словарь описания
    }
    function BuildSection(sSectionName: AnsiString): TStrDictionary;

    {
    Получить значение опции
    @param sSectionName Наименование секции
    @param sOptionName Наименование параметра
    @return Значение параметра в виде строки
    }
    function GetOptionValue(sSectionName: AnsiString; sOptionName: AnsiString): AnsiString;

    {
    Получить список имен опций одной секции
    @param sSectionName Наименование секции
    @return Список имен параметров указанной секции
    }
    function GetOptionNameList(sSectionName: AnsiString): TStringList;

    {
    Получить список имен секций
    @return Список имен секций
    }
    function GetSectionNameList(): TStringList;
    {
    Получить список имен опций одной секции
    @param sSectionName Наименование секции
    @return Список имен параметров указанной секции
    }
    function GetOptionNames(sSectionName: AnsiString): TArrayOfString;

    {
    Получить список имен секций
    @return Список имен секций
    }
    function GetSectionNames(): TArrayOfString;

  end;

var
  { Имя файла настроек }
  SETTINGS_INI_FILENAME: AnsiString = 'settings.ini';

  //SETTINGS_MANAGER: TICSettingsManager;


implementation

uses
  filefunc, log;

constructor TICSettingsManager.Create;
begin
  inherited Create;
  FContent := TIniDictionary.Create('Настройки программы');
end;

destructor TICSettingsManager.Destroy;
begin
  if FContent <> nil then
  begin
    FContent.Destroy;
    FContent := nil;
  end;

  // ВНИМАНИЕ! Нельзя использовать функции Free.
  // Если объект создается при помощи Create, то удаляться из
  // памяти должен с помощью Dуstroy
  // Тогда не происходит утечки памяти
  inherited Destroy;
end;

{
Генерация имени настроечного INI файла
}
function TICSettingsManager.GenIniFileName(): AnsiString;
var
  cur_path: AnsiString;
begin
  cur_path := ExtractFileDir(ParamStr(0));

  FIniFileName := JoinPath([cur_path, SETTINGS_INI_FILENAME]);

  log.DebugMsgFmt('Файл настроек: <%s>', [FIniFileName]);

  Result := FIniFileName;
end;

{
Вывод на экран текущих настроек для отладки.
}
procedure TICSettingsManager.PrintSettings();
var
  i_section, i_option: Integer;
  ini_file: TIniFile;
  sections: TStringList;
  section_name: AnsiString;
  options: TStringList;
  option: AnsiString;
begin
  if FIniFileName = '' then
  begin
    log.WarningMsg('Не определен INI файл настроек для отображения');
    Exit;
  end;
  if not FileExists(FIniFileName) then
  begin
    log.WarningMsgFmt('Файл настроек программы <%s> не найден', [FIniFileName]);
    Exit;
  end;

  ini_file := TIniFile.Create(FIniFileName);
  log.ServiceMsgFmt('Файл настроек программы <%s>:', [FIniFileName]);
  // ВНИМАНИЕ! Перед использованием списков строк в функции
  // надо их создать/выделить под них память
  sections := TStringList.Create;
  options := TStringList.Create;
  try
    try
      ini_file.ReadSections(sections);
      for i_section :=0 to sections.Count - 1 do
      begin
        section_name := sections[i_section];
        log.ServiceMsgFmt('[%s]', [section_name]);

        options.Clear;
        ini_file.ReadSectionValues(section_name, options);
        for i_option :=0 to options.Count - 1 do
        begin
          option := options[i_option];
          if AnsiStartsStr(';', option) then
            // Это коментарий обрабатывать не надо
            continue;
          log.ServiceMsgFmt(#9'%s', [option]);
        end;
      end;
    finally
      ini_file.Free;
    end;
  except
    log.FatalMsg('Ошибка печати настроек программы');
  end;
  // ВНИМАНИЕ! В конце обязательно освободить память
  options.Free;
  sections.Free;
end;

{
Загрузка настроек из INI файла.
Содержимое INI файла грузиться в Content.
@param (sINIFileName Полное имя конфигурационного файла.
        Если не определено, то генерируется.)
@return: (True - загрузка параметров прошла успешно,
          False - загрузка не прошла по какой-либо причине)
}
function TICSettingsManager.LoadSettings(sINIFileName: AnsiString): Boolean;
begin
  if sINIFileName = '' then
    sINIFileName := GenINIFileName();

  Result := False;
  if FileExists(sINIFileName) then
  begin
    Result := FContent.LoadIniFile(sIniFileName);
    if FContent.IsEmpty then
    begin
      Result := False;
      log.WarningMsgFmt('Не определены настройки в INI файле <%s>' , [sIniFileName]);
    end;
  end;
end;

{
Собрать полное описание секции с учетом ключа parent.
Через ключ parent можно наследовать описание секции.
@param (sSectionName Наименование запрашиваемой секции)
@return (Словарь секции дополненный переменными из секции указанной в parent.
    Сборка данных производиться рекурсивно.)
}
function TICSettingsManager.BuildSection(sSectionName: Ansistring): TStrDictionary;
var
  section, parent_section, result_section: TStrDictionary;
  obj_section: TStrDictionary;
  i: Integer;
  parent_section_list: Array Of String;
  parent_section_name: AnsiString;

begin
  if strfunc.IsEmptyStr(sSectionName) then
  begin
    Result := nil;
    Exit;
  end;

  // Создаем объект секции
  section := TStrDictionary.Create(sSectionName);
  if FContent.HasKey(sSectionName) then
  begin
    // Если запрашиваеммая секция есть в INI файле, то обновить объект секции
    obj_section := FContent.GetByName(sSectionName) As TStrDictionary;
    if obj_section.IsEmpty then
      log.WarningMsgFmt('Cекция <%s> пустая', [sSectionName]);

    // В секции из INI файла может отсутствовать наименование
    // поэтому добавляем его
    if not obj_section.HasKey('name') then
      obj_section.AddStrValue('name', sSectionName);
    // DebugMsg(Format('Класс секции <%s>', [obj_section.ClassName]));
    if obj_section <> nil then
    begin
      section.Update(obj_section);
      //section.PrintKeys;
    end
    else
      log.WarningMsgFmt('Не определена секция <%s> в настройках', [sSectionName]);
  end
  else
  begin
    section.AddStrValue('name', sSectionName);
    log.WarningMsgFmt('Не найдена секция <%s> в настройках среди:', [sSectionName]);
    FContent.PrintKeys;
  end;

  if not section.HasKey('parent') then
  begin
    // Если нет ссылки на родительское описание просто вернуть созданную секцию
    Result := section;
    Exit;
  end
  else if section.GetStrValue('parent') = '' then
  begin
    // Если ключ parent есть, но он не определен, то удаляем ключ parent bp секции и
    // возвращаем созданную секцию
    section.DelItem('parent');
    Result := section;
    Exit;
  end
  else if not FContent.HasKey(section.GetStrValue('parent')) then
  begin
    // Если описание секции с именем указанным в parent нет в INI файле, то
    // удаляем ключ parent из описания секции, сообщаем об ошибке и
    // возвращаем созданную секцию
    log.WarningMsgFmt('Запрашиваемая секция <%s> как родительская для <%s> не найдена', [section.GetStrValue('parent'), sSectionName]);
    section.DelItem('parent');
    Result := section;
    Exit;
  end
  else
    // В качестве родительского ключа может указываться список имен
    // Проверяем такой случай
    if IsParseStrList(section.GetStrValue('parent')) then
    begin
      // Список имен
      parent_section_list := ParseStrArray(section.GetStrValue('parent'));
      result_section := TStrDictionary.Create(sSectionName);
      for i := 0 to Length(parent_section_list) - 1 do
      begin
        parent_section_name := parent_section_list[i];
        parent_section := BuildSection(parent_section_name);
        if parent_section <> nil then
        begin
          result_section.Update(parent_section);
          // !!! После обновления результирующей секции необходимо освободить память
          parent_section.Destroy;
          parent_section := nil;
        end;
      end;
      result_section.Update(section);
      // !!! После обновления результирующей секции необходимо освободить память
      section.Destroy;
      section := nil;
      result_section.DelItem('parent');
      Result := result_section;
      Exit;
    end
    else
    begin
      // Имя родительской секции
      parent_section := BuildSection(section.GetStrValue('parent'));
      if parent_section <> nil then
      begin
        parent_section.Update(section);
        // !!! После обновления результирующей секции необходимо освободить память
        section.Destroy;
        section := nil;
        parent_section.DelItem('parent');
      end;
      Result := parent_section;
      Exit;
    end;

  // Все другие случаи считаем ошибочные
  section.Destroy;
  section := nil;
  Result := nil;
end;

{
Проверка существования файла настройки.
@param (sINIFileName Полное имя конфигурационного файла.
        Если None, то генерируется )
}
function TICSettingsManager.ExistsIniFile(sINIFileName: AnsiString): Boolean;
begin
  if sINIFileName = '' then
    sINIFileName := GenIniFileName();

  Result := FileExists(sINIFileName);
end;

{
Получить значение опции
}
function TICSettingsManager.GetOptionValue(sSectionName: Ansistring; sOptionName: Ansistring): AnsiString;
begin
  Result := FContent.GetOptionValue(sSectionName, sOptionName);
end;

{
Получить список имен опций одной секции
@param sSectionName Наименование секции
@return Список имен параметров указанной секции
}
function TICSettingsManager.GetOptionNameList(sSectionName: AnsiString): TStringList;
var
  section: TStrDictionary;
begin
  if FContent.HasKey(sSectionName) then
  begin
    section := FContent.GetByName(sSectionName) As TStrDictionary;
    if section <> nil then
    begin
      Result := section.GetKeys();
    end;
  end;
end;

{
Получить список имен секций
@return Список имен секций
}
function TICSettingsManager.GetSectionNameList(): TStringList;
begin
  Result := FContent.GetKeys();
end;

{
Получить список имен опций одной секции
@param sSectionName Наименование секции
@return Список имен параметров указанной секции
}
function TICSettingsManager.GetOptionNames(sSectionName: AnsiString): TArrayOfString;
var
  i: Integer;
  option_names: TStringList;
  section: TStrDictionary;
begin

  if FContent.HasKey(sSectionName) then
  begin
    section := FContent.GetByName(sSectionName) As TStrDictionary;
    if section <> nil then
    begin
      // Result := section.GetStrValue(sOptionName);
      option_names := section.GetKeys();

      SetLength(Result, option_names.Count);
      for i := 0 to option_names.Count - 1 do
        Result[i] := option_names[i];

      option_names.Free;
    end;
  end;
end;

{
Получить список имен секций
@return Список имен секций
}
function TICSettingsManager.GetSectionNames(): TArrayOfString;
var
  i: Integer;
  section_names: TStringList;
begin
  section_names := FContent.GetKeys();

  SetLength(Result, section_names.Count);
  for i := 0 to section_names.Count - 1 do
    Result[i] := section_names[i];

  section_names.Free;
end;

end.

