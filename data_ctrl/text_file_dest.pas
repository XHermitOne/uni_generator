{
Модуль класса генерации тектовых файлов по шаблону.

Версия: 0.0.1.1
}
unit text_file_dest;

{$mode objfpc}{$H+}

interface

uses
    Classes, SysUtils,
    obj_proto,
    dictionary,
    strfunc,
    exttypes,
    tag_list;

const
  TEXT_FILE_TYPE: AnsiString = 'TXT_FILE';

  RESERV_PROPERTIES: Array [1..6] Of String = ('type', 'name', 'description', 'filename', 'dirname', 'template');

  FILE_SIGNATURE: AnsiString = 'FILE: ';


type
  {
  Класс доступа к таблице PostgreSQL для записи значений тегов.
  }
  TICTextFileDest = class(TICObjectProto)

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

    {
    Запуск генерации текстового файла по контексту.
    @param AContext: Контекст.
    @param sTemplateFilename: Файл шаблона.
    @param sDestFilename: Результирующий файл.
    @return: Результат записи - True - запись прошла успешно False - ошибка
    }
    function GenerateFile(AContext: TStrDictionary; sTemplateFilename: AnsiString; sDestFilename: AnsiString): Boolean;

end;

implementation

uses
  DateUtils,
  JTemplate,

  log,
  sysfunc,
  filefunc,
  execfunc;

constructor TICTextFileDest.Create;
begin
  inherited Create;
end;


destructor TICTextFileDest.Destroy;
begin
  // ВНИМАНИЕ! Нельзя использовать функции Free.
  // Если объект создается при помощи Create, то удаляться из
  // памяти должен с помощью Dуstroy
  // Тогда не происходит утечки памяти
  inherited Destroy;
end;

{ Выбрать описания тегов из свойств }
function TICTextFileDest.CreateTags(): TStrDictionary;
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
function TICTextFileDest.WriteAll(dtTime: TDateTime): Boolean;
var
  tags: TStrDictionary;
  filename, dirname, template: AnsiString;
  curYear, curMonth, curDay : Word;
  curHour, curMin, curSec, curMilli : Word;

begin
  log.InfoMsgFmt('Запись всех внутренних данных. Объект <%s>', [Name]);

  Result := True;

  { Проверка на текущее время }
  if dtTime = 0 then
    dtTime := Now;

  log.DebugMsgFmt('Текущее актуальное время: %s', [DateTimeToStr(dtTime)]);

  filename := Properties.GetStrValue('filename');
  dirname := Properties.GetStrValue('dirname');
  log.DebugMsgFmt('Данные о результирующе папке <%s>. Данные о результирующем файле <%s>', [dirname, filename]);
  template := Properties.GetStrValue('template');
  if strfunc.IsStartsWith(template, FILE_SIGNATURE) then
     template := strfunc.ReplaceStart(template, FILE_SIGNATURE, '');

  tags := CreateTags();
  try

    { Добавляем к тегам временные значения }
    DateUtils.DecodeDateTime(dtTime, curYear, curMonth, curDay,
                             curHour, curMin, curSec, curMilli);

    tags.AddStrValue('year_str', FormatDateTime('YYYY', dtTime));
    tags.AddStrValue('month_str', FormatDateTime('MM', dtTime));
    tags.AddStrValue('day_str', FormatDateTime('DD', dtTime));
    tags.AddStrValue('hour_str', FormatDateTime('HH', dtTime));
    tags.AddStrValue('minute_str', FormatDateTime('NN', dtTime));
    tags.AddStrValue('second_str', FormatDateTime('SS', dtTime));
    tags.AddStrValue('millisecond_str', IntToStr(curMilli));

    tags.AddStrValue('year', IntToStr(curYear));
    tags.AddStrValue('month', IntToStr(curMonth));
    tags.AddStrValue('day', IntToStr(curDay));
    tags.AddStrValue('hour', IntToStr(curHour));
    tags.AddStrValue('minute', IntToStr(curMin));
    tags.AddStrValue('second', IntToStr(curSec));
    tags.AddStrValue('millisecond', IntToStr(curMilli));

    { Добавляем к тегам переменные окружения }
    { Полный путь к домашней папке }
    tags.AddStrValue('home_dir', filefunc.GetHomeDir());
    { Имя компьютера }
    tags.AddStrValue('computername', sysfunc.GetNetComputerName());

    try
      filename := strfunc.Generate(tags, filename);
      dirname := strfunc.Generate(tags, dirname);
    except
      log.FatalMsgFmt('Ошибка генерации имени результирующего файла <%s/%s>', [dirname, filename]);
      Result := False;
      tags.Destroy();
      Exit;
    end;
    { Проверяем если нет такой директории то создаем ее }
    dirname := filefunc.NormalPathFileName(dirname);
    log.InfoMsgFmt('Результирующая папка <%s>. Результирующий файл <%s>', [dirname, filename]);
    filefunc.CreateDirPathTree(dirname);
    filename := filefunc.JoinPath([dirname, filename]);
    log.InfoMsgFmt('Запись в файл <%s>...', [filename]);

    Result := GenerateFile(tags, template, filename);
    log.InfoMsgFmt('...Запись в файл <%s>', [filename]);
  except
    log.FatalMsgFmt('Ошибка записи данных в приемник <%s>', [Name]);
    Result := False;
  end;
  tags.Destroy();
end;

{
Запуск генерации текстового файла по контексту.
@param AContext: Контекст.
@param sTemplateFilename: Файл шаблона.
@param sDestFilename: Результирующий файл.
@return: Результат записи - True - запись прошла успешно False - ошибка
}
function TICTextFileDest.GenerateFile(AContext: TStrDictionary; sTemplateFilename: AnsiString; sDestFilename: AnsiString): Boolean;
var
  string_stream: TStringStream;
  template_stream: JTemplate.TJTemplateStream;
  i: Integer;
  variable_name, value: AnsiString;

begin
  Result := True;

  template_stream := JTemplate.TJTemplateStream.Create;

  try
    if FileExists(sTemplateFilename) then
    begin
      log.InfoMsgFmt('Загрузка шаблона из файла <%s>', [sTemplateFilename]);
      template_stream.LoadFromFile(sTemplateFilename);
    end
    else
    begin
      log.InfoMsg('Шаблон берется из строки');
      string_stream := TStringStream.Create(sTemplateFilename);
      template_stream.LoadFromStream(string_stream);
      string_stream.Destroy;
    end;

    // ВНИМАНИЕ! Переменные д.б. отсортированы в обратном порядке по длине имени переменной
    // иначе замена переменных будет не корректна
    AContext.Sort();

    // Добавление переменных из контекста
    for i := AContext.Count - 1 downto 0 do
    begin
      variable_name := AContext.GetKey(i);
      value := AContext.GetStrValue(variable_name);
      value := strfunc.ToUTF8(value);
      template_stream.Parser.Fields.Add(variable_name, value);
      log.InfoMsgFmt('Добавлена переменная в шаблонизатор <%s : %s>', [variable_name, value]);
    end;

    // Отключаем замену псевдо-символов
    template_stream.Parser.HtmlSupports := False;
    template_stream.Parser.Replace;
    template_stream.SaveToFile(sDestFilename);
  except
    log.FatalMsgFmt('Ошибка генерации файла <%s> по шаблону <%s>', [sDestFilename, sTemplateFilename]);
    Result := False;
  end;
  template_stream.Free;
end;

end.
