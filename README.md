<h1 align="center">Command Tips</h1>
<p align="center">

<img src="https://img.shields.io/badge/made%20by-MaxMavr-fcbf49" >

<img src="https://img.shields.io/badge/version-1.0.0-a7c957">
</p>

<p align="center" style="background-color: red; color: white;">
ВНИМАНИЕ ЭТО РИДМИ ВООБЩЕ НЕ ВЕРНО И НЕДОДЕЛАНО
</p>

Библиотека для начинающих пользователей Linux, помогающая сохранять и быстро находить часто используемые команды с комментариями и тегами.

## Быстрый старт

### Установка
```bash
git clone https://github.com/MaxMavr/command-tips.git
cd command-tips
sudo ln -s $(pwd)/bin/tips /usr/local/bin/tips
```

## Основные возможности

### Поиск и фильтрация
| Команда | Описание | Пример |
|---------|----------|--------|
| `tips -l, --list` | Показать все подсказки | `tips -l` |
| `tips -s, --search '<запрос>'` | Поиск по командам и комментариям | `tips -s 'архив'` |
| `tips --tags '<теги>'` | Фильтр по всем тегам *AND* | `tips --tags 'архивы,gzip'` |
| `tips --any-tags '<теги>'` | Фильтр по любому тегу *OR* | `tips --any-tags 'система,сеть'` |

### Добавление команд
| Команда | Описание | Пример |
|---------|----------|--------|
| `tips -a, --add '<команда>' '[комментарий]'` | Добавить новую команду | `tips -a 'tar -xzvf file.tar.gz' 'Распаковка архивов'` |
| `tips -y, --last-cmd '[комментарий]'` | Использовать последнюю команду из истории | `tips -y 'Обновление пакетов'` |

### Управление тегами
| Команда | Описание | Пример |
|---------|----------|--------|
| `tips --add-tags <номер> '<теги>'` | Добавить теги к записи | `tips --add-tags 5 'архивы,gzip'` |
| `tips --remove-tags <номер> '<теги>'` | Удалить теги у записи | `tips --remove-tags 5 'временные'` |

### Управление базой
| Команда | Описание | Пример |
|---------|----------|--------|
| `tips -e, --edit <номер>` | Редактировать запись | `tips -e 3` |
| `tips -d, --delete <номер>` | Удалить запись | `tips -d 3` |
| `tips -c, --clear` | Очистить всю базу | `tips -c` |
| `tips --backup <путь>` | Создать резервную копию | `tips --backup ~/backup.json` |

## Популярные сценарии использования

### Пример 1: Добавление команды с тегами
```bash
tips --add 'tar -xzvf file.tar.gz' 'Распаковка архивов' --tags архивы,gzip
```

### Пример 2: Поиск и фильтрация
```bash
tips --search 'архивы' --tags системные,backup
```

### Пример 3: Работа с буфером обмена
```bash
tips --copy 15  # Копирует команду в буфер
# Или:
tips --insert 15 | xclip -selection clipboard
```

### Пример 4: Использование истории команд
```bash
sudo apt update && tips --last-cmd 'Обновление пакетов' --tags система
```

### Пример 5: Расширенное редактирование
```bash
tips --add-tags 7 сети,nginx --remove-tags 7 временные
```

## Информация и статистика
| Команда | Описание | Пример |
|---------|----------|--------|
| `tips --count` | Количество записей | `tips --count` |
| `tips --stats` | Статистика по тегам | `tips --stats` |
| `tips --info <номер>` | Подробная информация | `tips --info 5` |

## Справка
```bash
tips -h, --help     # Показать справку
tips -v, --version  # Показать версию
```