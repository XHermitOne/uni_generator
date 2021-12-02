{
Функции работы со строками

Версия: 0.0.8.2
}
unit strfunc;

{$mode objfpc}{$H+}

interface

uses
    {$IFDEF windows}
    Windows,
    {$ENDIF}
    Classes, SysUtils, StrUtils,
    exttypes,
    dictionary,
    LConvEncoding;

const
  DELIMETER: Char = ',';
{
Разбивает строку с разделителями на части и возвращает массив частей
@param sString Строка
@param cDelim Символ разделителя
@return Массив строк
}
function SplitStr(sString: String; cDelim: Char = ','): TArrayOfString;

{
Объединение массива строк в одну строку
@param StringArray Массив строк
@param cDelim Символ разделителя
@return Объединенная строка
}
function JoinStr(StringArray : Array Of String; cDelim : Char = ','): AnsiString;
function JoinStr(StringArray: Array Of String; sDelim: AnsiString = ','): AnsiString;

{
Удалить обрамление кавычками одинарными и двойными из строки
@param sString Строка
@param sChar Обрамляющий символ
@return Строка с удаленными обрамляющими симвлами
}
function StripStr(sString: AnsiString; sChar: Char = ' '): AnsiString;

{
Распарсить строку, представляющую собой список строк
@param sString Обрабатываемая строка
@return Массив строк
}
function ParseStrArray(sString: AnsiString): TArrayOfString;

{
Проверка является ли строка серилизованным списком
@param sString Строка
@return True/False
}
function IsParseStrList(sString: AnsiString): Boolean;

{
Распарсить строку, представляющую собой список строк. Возврашает список строк.
@param sString Строка
@return Список строк
}
function ParseStrList(sString: AnsiString): TStringList;

{
Преобразование списка строк в строку вида [ aaaa, bbbb, cccc ]
@param StrList Спсок строк
@return Преобразованная строка
}
function ConvertStrListToString(StrList: TStringList): AnsiString;

{
Проверка есть ли строка в списке строк
@param sString Строка
@param StringArray Массив строк
@return True/False
}
function IsStrInList(sString: AnsiString; StringArray: Array of String): Boolean;

{
Проверка есть ли какая либо из указанных строк в строке
@param sWord Проверяемое слово
@param sString Строка, в которой производим поиск слова
@param bCaseSensentive Поиск с учетом регистра?
}
function IsWordInStr(sWord: AnsiString; sString: AnsiString; bCaseSensentive: Boolean=True): Boolean;
{
Проверка есть ли какая либо из указанных строк в строке
@param WordArray Массив искомых слов
@param sString Строка, в которой производим поиск
@param bCaseSensentive Поиск с учетом регистра?
}
function AnyWordInStr(WordArray: Array of String; sString: AnsiString; bCaseSensentive: Boolean=True): Boolean;

{ Перекодировка CP866 -> CP1251 и обратно }
{$IFDEF windows}
function StrOemToAnsi(const S: AnsiString): AnsiString;
function StrAnsiToOem(const S: AnsiString): AnsiString;
{$ENDIF}

{
Попытка перекодировать строку в UTF8. Функция сама определеяет кодировку строки и
затем преобразует в UTF8.
@param sStr Исходная строка
@return Преобразованная строка в UTF8
}
function ToUTF8(var sStr: AnsiString): AnsiString;

{
Перекодирование AnsiString строки в AnsiString другой кодировки.
@param sTxt Текст в AnsiString
@param sFromEncoding Исходная кодировка
@param sToEncoding Результирующая кодировка.
@param sCodePage Указание кодировки
@return Перекодированный текст
}
function EncodeString(sTxt: AnsiString; sFromEncoding: AnsiString; sToEncoding: AnsiString): AnsiString;

{
Проверка на начало строки с подстроки.
@param sTxt Проверяемый текст
@param sSubStr Проверяемая подстрока
@return True - sTxt начинается с sSubStr, False - нет.
}
function IsStartsWith(sTxt: AnsiString; sSubStr: AnsiString): Boolean;

{
Проверка на окончание строки с подстроки.
@param sTxt Проверяемый текст
@param sSubStr Проверяемая подстрока
@return True - sTxt оканчивается на sSubStr, False - нет.
}
function IsEndsWith(sTxt: AnsiString; sSubStr: AnsiString): Boolean;

{
Заменить подстроку sSrcStr в начале sTxt на sDstStr.
@param sTxt Исходный текст
@param sSrcStr Исходная подстрока
@param sDstStr Результирующая подстрока. По умолчанию пустая строка.
@return Строка с произведенными заменами
}
function ReplaceStart(sTxt: AnsiString; sSrcStr: AnsiString; sDstStr: AnsiString = ''): AnsiString;

{
Заменить подстроку sSrcStr в конце sTxt на sDstStr.
@param sTxt Исходный текст
@param sSrcStr Исходная подстрока
@param sDstStr Результирующая подстрока. По умолчанию пустая строка.
@return Строка с произведенными заменами
}
function ReplaceEnd(sTxt: AnsiString; sSrcStr: AnsiString; sDstStr: AnsiString = ''): AnsiString;

{
Заменить подстроку sSrcStr на sDstStr в sTxt. Произвести все замены.

@param sTxt Исходный текст
@param sSrcStr Исходная подстрока
@param sDstStr Результирующая подстрока. По умолчанию пустая строка.
@return Строка с произведенными заменами
}
function Replace(sTxt: AnsiString; sSrcStr: AnsiString; sDstStr: AnsiString = ''): AnsiString;

{
Заменить подстроку sSrcStr на sDstStr в sTxt. Произвести все замены без учета регистра.

@param sTxt Исходный текст
@param sSrcStr Исходная подстрока
@param sDstStr Результирующая подстрока. По умолчанию пустая строка.
@return Строка с произведенными заменами
}
function ReplaceIgnoreCase(sTxt: AnsiString; sSrcStr: AnsiString; sDstStr: AnsiString = ''): AnsiString;

{
Проверка на пустую строку.
@param sTxt Исходный текст
@return True - строка пустая False - не пустая строка.
}
function IsEmptyStr(sTxt: AnsiString): Boolean;

{
Запуск генерации строки по контексту.
@param AContext: Контекст.
@param sTemplate: Строка-шаблон.
@return: Сгенерированная строка.
}
function Generate(AContext: TStrDictionary; sTemplate: AnsiString): AnsiString;


implementation

uses
  JTemplate;

{
Разбивает строку с разделителями на части
и возвращает массив частей.
}
function SplitStr(sString: String; cDelim: Char): TArrayOfString;
begin
  Result := sString.Split([cDelim]);
end;

{
Объединение массива строк в одну строку.
}
function JoinStr(StringArray: Array Of String; cDelim: Char): AnsiString;
begin
  Result := ''.Join(cDelim, StringArray);
end;

{
Объединение массива строк в одну строку.
}
function JoinStr(StringArray: Array Of String; sDelim: AnsiString): AnsiString;
begin
  Result := ''.Join(sDelim, StringArray);
end;

{
Удалить обрамление кавычками одинарными и двойными из строки.
}
function StripStr(sString: AnsiString; sChar: Char): AnsiString;
begin
  Result := sString;
  if AnsiStartsStr(sChar, sString) then
    Result := Copy(sString, 2, Length(sString) - 1);
  if AnsiEndsStr(sChar, sString) then
    Result := Copy(sString, 1, Length(sString) - 1);

  if AnsiStartsStr(sChar, sString) or AnsiEndsStr(sChar, sString) then
    Result := StripStr(Result, sChar);
end;

{
Распарсить строку, представляющую собой список строк
Например:
  [ aaaa, bbbb, cccc ] или ['aaa', 'bbb', 'ccc']
}
function ParseStrArray(sString: AnsiString): TArrayOfString;
var
  i: Integer;
  result_list: Array Of String;
begin
  if AnsiStartsStr('[', sString) then
    sString := Copy(sString, 2, Length(sString) - 1);
  if AnsiEndsStr(']', sString) then
    sString := Copy(sString, 1, Length(sString) - 1);
  result_list := SplitStr(sString, DELIMETER);
  for i := 0 to Length(result_list) - 1 do
  begin
    result_list[i] := StripStr(result_list[i], ' ');
    result_list[i] := StripStr(result_list[i], #39);
    result_list[i] := StripStr(result_list[i], '"');
  end;
  Result := result_list;
end;

{
Проверка является ли строка серилизованным списком
}
function IsParseStrList(sString: AnsiString): Boolean;
begin
  Result := AnsiStartsStr('[', sString) and  AnsiEndsStr(']', sString);
end;

{
Распарсить строку, представляющую собой список строк
Например:
  [ aaaa, bbbb, cccc ] или ['aaa', 'bbb', 'ccc']
Возврашает список строк.
}
function ParseStrList(sString: AnsiString): TStringList;
var
  str_array: Array Of String;
  i: Integer;
  str_list: TStringList;
begin
  str_list := TStringList.Create;
  str_array := ParseStrArray(sString);
  for i := 0 to Length(str_array) - 1 do
    str_list.Add(str_array[i]);
  Result := str_list;
end;

{
Преобразование списка строк в строку вида:
[ aaaa, bbbb, cccc ]
}
function ConvertStrListToString(StrList: TStringList): AnsiString;
begin
  // ExtractStrings([','], [' '], PChar(result), StrList);
  StrList.Delimiter := DELIMETER;
  Result := '[' + Trim(StrList.DelimitedText) + ']';
end;

{ Проверка есть ли строка в списке строк }
function IsStrInList(sString: AnsiString; StringArray: Array of String): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to Length(StringArray) - 1 do
    if StringArray[i] = sString then
    begin
      Result := True;
      Exit;
    end;
end;

{ Проверка есть ли какая либо из указанных строк в строке }
function IsWordInStr(sWord: AnsiString; sString: AnsiString; bCaseSensentive: Boolean): Boolean;
begin
  if bCaseSensentive then
    Result := Pos(sWord, sString) >= 1
  else
    Result := Pos(LowerCase(sWord), LowerCase(sString)) >= 1;
end;

{ Проверка есть ли какая либо из указанных строк в строке }
function AnyWordInStr(WordArray: Array of String; sString: AnsiString; bCaseSensentive: Boolean): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 0 to Length(WordArray) - 1 do
  begin
    //log.DebugMsgFmt('Сравнение строк <%s> <%s> : %s', [WordArray[i], sString,
    //                BoolToStr(IsWordInStr(WordArray[i], sString, bCaseSensentive), '+', '-')]);
    if IsWordInStr(WordArray[i], sString, bCaseSensentive) then
    begin
      Result := True;
      Exit;
    end;
  end;
end;

{$IFDEF windows}
function StrOemToAnsi(const S: AnsiString): AnsiString;
begin
  if Length(S) = 0 then Result := ''
  else
    begin
      SetLength(Result, Length(S));
      OemToAnsiBuff(@S[1], @Result[1], Length(S));
    end;
end;
{$ENDIF windows}

//--------------------------------------------------------------------------------------------------

{$IFDEF windows}
function StrAnsiToOem(const S: AnsiString): AnsiString;
begin
  if Length(S) = 0 then Result := ''
  else
    begin
      SetLength(Result, Length(S));
      AnsiToOemBuff(@S[1], @Result[1], Length(S));
    end;
end;
{$ENDIF windows}

{
Попытка перекодировать строку в UTF8
}
function ToUTF8(var sStr: AnsiString): AnsiString;
var
  from: string;
begin
  from := GuessEncoding(sStr);
  Result := ConvertEncoding(sStr, from, EncodingUTF8);
end;

{
Перекодирование AnsiString строки в AnsiString другой кодировки.
@param sTxt Текст в AnsiString
@param sFromEncoding Исходная кодировка
@param sToEncoding Результирующая кодировка.
@param sCodePage Указание кодировки
@return Перекодированный текст
}
function EncodeString(sTxt: AnsiString; sFromEncoding: AnsiString; sToEncoding: AnsiString): AnsiString;
begin
  Result := '';

  // Приведем кодировки к нижнему регистру для использования
  sFromEncoding := LowerCase(sFromEncoding);
  if sFromEncoding = 'utf-8' then
    sFromEncoding := 'utf8';
  sToEncoding := LowerCase(sToEncoding);
  if sToEncoding = 'utf-8' then
    sToEncoding := 'utf8';

  if sFromEncoding = sToEncoding then
    // Если кодировки совпадают, то перекодировать не надо
    Result := sTxt
  else if (sFromEncoding = 'utf8') and (sToEncoding = 'cp866') then
    Result := LConvEncoding.UTF8ToCP866(sTxt)
  else if (sFromEncoding = 'utf8') and (sToEncoding = 'cp1251') then
    Result := LConvEncoding.UTF8ToCP1251(sTxt)
  else if (sFromEncoding = 'cp1251') and (sToEncoding = 'utf8') then
    Result := LConvEncoding.CP1251ToUTF8(sTxt)
  else if (sFromEncoding = 'cp1251') and (sToEncoding = 'cp866') then
    Result := LConvEncoding.UTF8ToCP866(LConvEncoding.CP1251ToUTF8(sTxt))
  else if (sFromEncoding = 'cp866') and (sToEncoding = 'utf8') then
    Result := LConvEncoding.CP866ToUTF8(sTxt)
  else if (sFromEncoding = 'cp866') and (sToEncoding = 'cp1251') then
    Result := LConvEncoding.UTF8ToCP1251(LConvEncoding.CP866ToUTF8(sTxt))
  else
    Result := LConvEncoding.ConvertEncoding(sTxt, sFromEncoding, sToEncoding);
end;

{
Проверка на начало строки с подстроки.
@param sTxt Проверяемый текст
@param sSubStr Проверяемая подстрока
@return True - sTxt начинается с sSubStr, False - нет.
}
function IsStartsWith(sTxt: AnsiString; sSubStr: AnsiString): Boolean;
var
  sub_str: AnsiString;
begin
  sub_str := Copy(sTxt, 0, Length(sSubStr));
  Result := sSubStr = sub_str;
end;

{
Проверка на окончание строки с подстроки.
@param sTxt Проверяемый текст
@param sSubStr Проверяемая подстрока
@return True - sTxt оканчивается на sSubStr, False - нет.
}
function IsEndsWith(sTxt: AnsiString; sSubStr: AnsiString): Boolean;
var
  sub_str: AnsiString;
begin
  sub_str := Copy(sTxt, Length(sTxt) - Length(sSubStr), Length(sSubStr));
  Result := sSubStr = sub_str;
end;

{
Заменить подстроку sSrcStr в начале sTxt на sDstStr.
@param sTxt Исходный текст
@param sSrcStr Исходная подстрока
@param sDstStr Результирующая подстрока. По умолчанию пустая строка.
@return Строка с произведенными заменами
}
function ReplaceStart(sTxt: AnsiString; sSrcStr: AnsiString; sDstStr: AnsiString): AnsiString;
begin
  Result := sTxt;
  if IsStartsWith(sTxt, sSrcStr) then
    // ВНИМАНИЕ! Берем следующий символ--------------V
    Result := sDstStr + Copy(sTxt, Length(sSrcStr) + 1, Length(sTxt) - Length(sSrcStr));
end;

{
Заменить подстроку sSrcStr в конце sTxt на sDstStr.
@param sTxt Исходный текст
@param sSrcStr Исходная подстрока
@param sDstStr Результирующая подстрока. По умолчанию пустая строка.
@return Строка с произведенными заменами
}
function ReplaceEnd(sTxt: AnsiString; sSrcStr: AnsiString; sDstStr: AnsiString = ''): AnsiString;
begin
  Result := sTxt;
  if IsEndsWith(sTxt, sSrcStr) then
    Result := Copy(sTxt, Length(sTxt) - Length(sSrcStr), Length(sSrcStr)) + sDstStr;
end;

{
Заменить подстроку sSrcStr на sDstStr в sTxt. Произвести все замены.

@param sTxt Исходный текст
@param sSrcStr Исходная подстрока
@param sDstStr Результирующая подстрока. По умолчанию пустая строка.
@return Строка с произведенными заменами
}
function Replace(sTxt: AnsiString; sSrcStr: AnsiString; sDstStr: AnsiString = ''): AnsiString;
begin
  Result := StringReplace(sTxt, sSrcStr, sDstStr, [rfReplaceAll]);
end;

{
Заменить подстроку sSrcStr на sDstStr в sTxt. Произвести все замены без учета регистра.

@param sTxt Исходный текст
@param sSrcStr Исходная подстрока
@param sDstStr Результирующая подстрока. По умолчанию пустая строка.
@return Строка с произведенными заменами
}
function ReplaceIgnoreCase(sTxt: AnsiString; sSrcStr: AnsiString; sDstStr: AnsiString = ''): AnsiString;
begin
  Result := StringReplace(sTxt, sSrcStr, sDstStr, [rfReplaceAll, rfIgnoreCase]);
end;

{
Проверка на пустую строку.
@param sTxt Исходный текст
@return True - строка пустая False - не пустая строка.
}
function IsEmptyStr(sTxt: AnsiString): Boolean;
begin
  Result := Length(sTxt) = 0;
end;

{
Запуск генерации строки по контексту.
@param AContext: Контекст.
@param sTemplate: Строка-шаблон.
@return: Сгенерированная строка.
}
function Generate(AContext: TStrDictionary; sTemplate: AnsiString): AnsiString;
var
  string_stream: TStringStream;
  template_stream: JTemplate.TJTemplateStream;
  i: Integer;
  name, value: AnsiString;

begin
  Result := '';
  template_stream := JTemplate.TJTemplateStream.Create;
  string_stream := TStringStream.Create(sTemplate);

  try
    template_stream.LoadFromStream(string_stream);

    for i := 0 to AContext.Count - 1 do
    begin
      name := AContext.GetKey(i);
      value := AContext.GetStrValue(name);
      value := strfunc.ToUTF8(value);
      template_stream.Parser.Fields.Add(name, value);
    end;

    template_stream.Parser.Replace;
    Result := template_stream.Parser.Content;
  finally
    string_stream.Destroy;
    template_stream.Free;
  end;
end;

end.

