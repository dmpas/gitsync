﻿///////////////////////////////////////////////////////////////////
//
// Служебный модуль с реализацией работы команды export
//
// Представляет собой модификацию приложения gitsync от 
// команды oscript-library
//
// Структура модуля реализована в соответствии с рекомендациями 
// oscript-app-template (C) EvilBeaver
//
///////////////////////////////////////////////////////////////////

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт

	ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Выполнить локальную синхронизацию, без pull/push");
	
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ПутьКХранилищу", "Файловый путь к каталогу хранилища конфигурации 1С.");
	Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "ЛокальныйКаталогГит", "Каталог исходников внутри локальной копии git-репозитария.");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-email", "<домен почты для пользователей git>");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-v8version", "<Маска версии платформы (8.3, 8.3.5, 8.3.6.2299 и т.п.)>");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-debug", "<on|off>");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-verbose", "<on|off>");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-format", "<hierarchical|plain>");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-minversion", "<номер минимальной версии для выгрузки>");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-maxversion", "<номер максимальной версии для выгрузки>");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-limit", "<выгрузить неболее limit версий от текущей выгруженной>");
	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-tempdir", "<Путь к каталогу временных файлов>");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "-process-fatform-modules", "Переименовывать модули обычных форм в Module.bsl");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "-check-authors", "Проверка файла AUTHORS, на наличие всех авторов коммитов ");

	Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-amount-look-for-license", "<число> количество повторов получения лицензии (попытка подключения каждые 10 сек), 0 - без ограничений");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "-stop-if-empty-comment", "Остановить, если Комментарий к версии пустой");
	Парсер.ДобавитьПараметрФлагКоманды(ОписаниеКоманды, "-auto-set-tags", "Автоматическая установка тэгов по версия конфиграции");


	Парсер.ДобавитьКоманду(ОписаниеКоманды);

КонецПроцедуры // ЗарегистрироватьКоманду

Функция ВыполнитьКоманду(Знач ПараметрыКоманды, Знач ДополнительныеПараметры) Экспорт

	ЛокальныйКаталогГит = ПараметрыКоманды["ЛокальныйКаталогГит"];
	Формат = ПараметрыКоманды["-format"];
	МинВерсия = ПараметрыКоманды["-minversion"];
	МаксВерсия = ПараметрыКоманды["-maxversion"];
	Лимит = ПараметрыКоманды["-limit"];
	ПереименовыватьФайлМодуляОбычнойФормы = ПараметрыКоманды["-process-fatform-modules"];
	ПроверитьАвторовХранилища = ПараметрыКоманды["-check-authors"];
	ПрерватьВыполнениеБезКомментарияКВерсии = ПараметрыКоманды["-stop-if-empty-comment"];
	АвтоматическаяУстановкаТэговПоВерсиям = ПараметрыКоманды["-auto-set-tags"];

	Если ЛокальныйКаталогГит = Неопределено Тогда

		ЛокальныйКаталогГит = ТекущийКаталог();

	КонецЕсли;

	Если ПроверитьАвторовХранилища = Неопределено Тогда

		ПроверитьАвторовХранилища = Ложь;

	КонецЕсли;

	Если Формат = Неопределено Тогда

		Формат = РежимВыгрузкиФайлов.Авто;

	КонецЕсли;

	Если МинВерсия = Неопределено Тогда
	
		МинВерсия = 0;

	КонецЕсли;

	Если МаксВерсия = Неопределено Тогда
	
		МаксВерсия = 0;

	КонецЕсли;

	Если Лимит = Неопределено Тогда
	
		Лимит = 0;

	КонецЕсли;

	Если ПрерватьВыполнениеБезКомментарияКВерсии = Неопределено Тогда

		ПрерватьВыполнениеБезКомментарияКВерсии = Ложь;

	КонецЕсли;

	Если АвтоматическаяУстановкаТэговПоВерсиям = Неопределено Тогда

		АвтоматическаяУстановкаТэговПоВерсиям = Ложь;

	КонецЕсли;

	МаксВерсия = Число(МаксВерсия);
	МинВерсия = Число(МинВерсия);
	Лимит = Число(Лимит);

	Распаковщик = РаспаковщикКонфигурации.ПолучитьИНастроитьРаспаковщик(ПараметрыКоманды, ДополнительныеПараметры);
	Распаковщик.ВерсияПлатформы				= ПараметрыКоманды["-v8version"];
	Распаковщик.ДоменПочтыДляGitПоУмолчанию	= ПараметрыКоманды["-email"];
	Распаковщик.ПереименовыватьФайлМодуляОбычнойФормы = ПереименовыватьФайлМодуляОбычнойФормы;
	ДополнительныеПараметры.Лог.Информация("Начинаю выгрузку исходников");
	РаспаковщикКонфигурации.ВыполнитьЭкспортИсходников(Распаковщик, 
                                                        ПараметрыКоманды["ПутьКХранилищу"], 
                                                        ЛокальныйКаталогГит, 
                                                        МинВерсия, 
                                                        МаксВерсия, 
                                                        Формат,
                                                        ,
                                                        , 
                                                        Лимит, 
														ПрерватьВыполнениеБезКомментарияКВерсии,
														,
														АвтоматическаяУстановкаТэговПоВерсиям,
														ПроверитьАвторовХранилища);
	ДополнительныеПараметры.Лог.Информация("Выгрузка завершена");

	Возврат МенеджерКомандПриложения.РезультатыКоманд().Успех;

КонецФункции // ВыполнитьКоманду
