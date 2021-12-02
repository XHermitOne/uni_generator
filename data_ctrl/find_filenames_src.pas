{
Источник данных поиска файлов по маске

Объект имеет единственный тег состояния
filenames - список найденных файлов.
В INI файле его указывать не надо.

Версия: 0.0.0.1
}

unit find_filenames_src;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ActiveX,
  obj_proto, dictionary, strfunc,
  tag_list;

const
FIND_FILENAMES_SRC_NODE_TYPE: AnsiString = 'FIND_FILENAMES';

RESERV_PROPERTIES: Array [1..6] Of String = ('type', 'name', 'description', 'folder', 'mask', 'into_subdirs');

type
  {
  Класс поиска файлов по маске.
  }
  TICFindFilenamesNode = class(TICObjectProto)

  private
    { Папка поиска }
    FFolder: AnsiString;

    { Маска поиска }
    FMask: AnsiString;

    { Искать в подпапках? }
    FIntoSubDirs: Boolean;

  public
    constructor Create;
    destructor Destroy; override;

    { Выбрать описания тегов из свойств }
    function CreateTags(): TStrDictionary;

    {
    Чтение всех внутренних данных, описанных в свойствах.
    @param dtTime: Время актуальности за которое необходимо получить данные.
                  Если не определено, то берется текущее системное время.
    @return Список прочитанных значений.
    }
    function ReadAll(dtTime: TDateTime = 0): TStringList; override;

  end;

implementation

uses
  //LCLIntf, // Для вычисления времени выполнения
  FileUtil,  // Определены функции поиска файла
  log,
  execfunc;

constructor TICFindFilenamesNode.Create;
begin
  inherited Create;
end;

destructor TICFindFilenamesNode.Destroy;
begin
  inherited Destroy;
end;

{
Чтение всех внутренних данных, описанных в свойствах.
@param dtTime: Время актуальности за которое необходимо получить данные.
              Если не определено, то берется текущее системное время.
@return Список прочитанных значений.
}
function TICFindFilenamesNode.ReadAll(dtTime: TDateTime): TStringList;
var
  search_folder: AnsiString;
  search_mask: AnsiString;
  search_subdirs: Boolean;
  filenames: TStringList;
  filenames_as_str: AnsiString;
  i: Integer;

begin
  State := CreateTags;

  search_folder := Properties.GetStrValue('folder');
  if strfunc.IsStartsWith(search_folder, obj_proto.LINK_SIGNATURE) then
    search_folder := GetLinkValue(search_folder)
  else if strfunc.IsStartsWith(search_folder, execfunc.EXEC_SIGNATURE) then
    search_folder := execfunc.ExecutePascalScript(search_folder, nil);

  search_mask := Properties.GetStrValue('mask');
  search_subdirs := StrToBool(Properties.GetStrValue('into_subdirs'));

  filenames := FileUtil.FindAllFiles(search_folder, search_mask, search_subdirs);

  if filenames.Count > 0 then
    for i := 0 to filenames.Count - 1 do
      log.InfoMsgFmt('Найден файл <%s>', [filenames[i]])
  else
    log.WarningMsgFmt('Файлы в папке <%s> по маске <%s> не найдены', [search_folder, search_mask]);

  State.SetStrList('filenames', filenames);
  filenames_as_str := strfunc.ConvertStrListToString(filenames);
  //log.DebugMsgFmt('Список файлов в виде строки <%s>', [filenames_as_str]);
  State.SetStrValue('filenames_as_string', filenames_as_str);
  Result := filenames;
end;


{ Выбрать описания тегов из свойств }
function TICFindFilenamesNode.CreateTags(): TStrDictionary;
var
  tags: TStrDictionary;

begin
  tags := TStrDictionary.Create(Format('Теги объекта <%s>', [self.Name]));
  //tags.SetStrList('filenames', nil);
  Result := tags;
end;

end.
