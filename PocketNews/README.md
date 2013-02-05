# PocketNews /
***
В тази директория се намират модулите на приложението:

##Config.pm          
ООП обвивка за конфигурацията.
Зависи от: 
+ XML::Simple
+ Cwd
+ File::Util


##NewsFetcher.pm    
Служи за взимането на новините, подготовката им и препаботката им в електронна книга.
Зависи от:
+ XML::RSS::Parser
+ LWP::Simple
+ Cwd
+ File::Util
+ HTML::Template
+ Time::Piece
+ EBook::EPUB
+ PocketNews::Weather
+ WWW::BashOrg

##DB.pm   
Обвивка за DBI:SQLite с помощни методи;
Зависи от:
+ DBI
+ Cwd
+ File::Util

##Weather.pm         
Служи за взимане на прогноза за времето на определена локация.
Зависи от:
+ Yahoo::Weather

***
