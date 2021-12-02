{
Узел-получатель удаления не актуальных файлов.

Версия: 0.0.0.1
}

unit delete_files_dst;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ActiveX,
  obj_proto, dictionary, strfunc,
  tag_list;

const
DELETE_FILES_DST_NODE_TYPE: AnsiString = 'DELETE_FILES';

RESERV_PROPERTIES: Array [1..5] Of String = ('type', 'name', 'description', 'filenames', 'not_actual_days');

type
  {
  Класс удаления не актальных файлов.
  }
  TICDeleteFilesDst = class(TICObjectProto)

  private

  public
    constructor Create;
    destructor Destroy; override;

    { Выбрать описания тегов из свойств }
    function CreateTags(): TStrDictionary;

    {
    Запись всех внутренних данных
    @param dtTime: Время актуальности данных.
                  Если не определено, то берется текущее системное время.
    @return Результат записи - True - запись прошла успешно False - ошибка
    }
    function WriteAll(dtTime: TDateTime = 0): Boolean; override;

  end;

 implementation

 uses
   DateUtils,
   //JTemplate,

   log,
   //sysfunc,
   filefunc,
   execfunc;

constructor TICDeleteFilesDst.Create;
begin
  inherited Create;
end;


destructor TICDeleteFilesDst.Destroy;
begin
  // ВНИМАНИЕ! Нельзя использовать функции Free.
  // Если объект создается при помощи Create, то удаляться из
  // памяти должен с помощью Dуstroy
  // Тогда не происходит утечки памяти
  inherited Destroy;
end;

{ Выбрать описания тегов из свойств }
function TICDeleteFilesDst.CreateTags(): TStrDictionary;
var
  i: Integer;
  key, value: AnsiString;
  tags: TStrDictionary;

begin
  tags := TStrDictionary.Create(Format('Теги объекта <%s>', [self.Name]));
  for i := 0 to Properties.Count - 1 do
  begin
    key := Properties.GetKey(i);
    if not IsStrInList(key, RESERV_PROPERTIES) then
    begin
      value := Properties.GetStrValue(key);

      if strfunc.IsStartsWith(value, obj_proto.LINK_SIGNATURE) then
        value := GetLinkValue(value)
      else if strfunc.IsStartsWith(value, execfunc.EXEC_SIGNATURE) then
        value := execfunc.ExecutePascalScript(value, tags);
      tags.AddStrValue(key, value);
    end;
  end;
  Result := tags;
end;

{
Запись всех внутренних данных
@param dtTime: Время актуальности данных.
               Если не определено, то берется текущее системное время.
@return Результат записи - True - запись прошла успешно False - ошибка
}
function TICDeleteFilesDst.WriteAll(dtTime: TDateTime): Boolean;
var
  tags: TStrDictionary;
  filenames: TStringList;
  filenames_property: AnsiString;
  not_actual_days: Integer;

  curYear, curMonth, curDay : Word;
  curHour, curMin, curSec, curMilli : Word;
  dtNotActual: TDateTime;

  i: Integer;
  dt: TDateTime;

begin
  log.InfoMsgFmt('Запись всех внутренних данных. Объект <%s>', [Name]);

  Result := True;

  { Проверка на текущее время }
  if dtTime = 0 then
    dtTime := Now;

  log.DebugMsgFmt('Текущее актуальное время: %s', [DateTimeToStr(dtTime)]);

  tags := CreateTags();
  // Список файлов
  filenames_property := Properties.GetStrValue('filenames');
  //log.DebugMsgFmt('Список файлов <%s>', [filenames_property]);
  if strfunc.IsStartsWith(filenames_property, obj_proto.LINK_SIGNATURE) then
    filenames_property := GetLinkValue(filenames_property)
  else if strfunc.IsStartsWith(filenames_property, execfunc.EXEC_SIGNATURE) then
    filenames_property := execfunc.ExecutePascalScript(filenames_property, tags);
  //log.DebugMsgFmt('Поиск не актуальных файлов среди %s', [filenames_property]);
  if not strfunc.IsEmptyStr(filenames_property) then
    filenames := strfunc.ParseStrList(filenames_property)
  else
    filenames := nil;

  not_actual_days := StrToInt(Properties.GetStrValue('not_actual_days'));

  DateUtils.DecodeDateTime(dtTime, curYear, curMonth, curDay,
                           curHour, curMin, curSec, curMilli);
  dtNotActual := DateUtils.EncodeDateTime(curYear, curMonth, curDay - not_actual_days, 0, 0, 0, 0);

  if filenames <> nil then
  begin
    for i := 0 to filenames.Count - 1 do
    begin
      dt := filefunc.GetCreateFileDateTime(filenames[i]);
      if dt < dtNotActual then
      begin
        log.InfoMsgFmt('Удаление не актуального файла <%s> [%s : %s]', [filenames[i], DateTimeToStr(dt), DateTimeToStr(dtNotActual)]);
        Result := filefunc.DelFile(filenames[i]);
        if Result = False then
        begin
          tags.Destroy;
          Exit;
        end;
      end
      else
        log.InfoMsgFmt('Файл <%s> актуален [%s : %s]', [filenames[i], DateTimeToStr(dt), DateTimeToStr(dtNotActual)]);
    end;
    // Освобождаем список файлов
    filenames.Free;
  end;
  tags.Destroy;
end;

end.
