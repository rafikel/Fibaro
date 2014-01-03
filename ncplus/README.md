Fibaro NC+
==========

FIBARO HC2 + DEKODER TELEWIZJI NC PLUS
http://fibaro.rafikel.pl (2013-2014)

Skrypt LUA urządzenia wirtualnego Fibaro oraz centralki 
HC2, który całkowicie automatycznie utworzy i skonfiguruje 
urządzenie wirtualne w centralce do obsługi dekodera 
telewizji NC Plus (dekodery MediaBox)!

Potrzebne: 
1. Twoja nazwa urządzenia (np. Dekoder NC+). 
2. Adres IP oraz port (najpewniej 8080) dekodera. 
3. Hasło i login do centralki podane na początku skryptu. 

Co skrypt zrobi: 
1. Znajdzie dekoder pod podanym adresem i pobierze z niego 
   wszelkie potrzebne dane.
2. Przygotuje pełen zestaw przycisków, które będa dostępne
   w interfejsie użytkownika oraz scenach blokowych.
3. Pobierze z serwera fibaro.rafikel.pl oraz wgra do 
   centralki zestaw ikonek graficznych dla urządzenia.
4. Utworzy zmienna globalną, która odzwierciedlać będzie 
   stan dekodera (nazwa zmiennej na podstawie podanej nazwy 
   urządzenia wirtualnego).
5. W pełni umożliwi na sterowanie i odczytywanie stanu 
   dekodera z poziomu scen blokowych. 

Instrukcja: 
1. Utwórz nowe urządzenie wirtualne. 
2. Podaj swoją nazwę (np. "Dekoder NC+") oraz adres IP 
   i port TCP dekodera (najpewniej 8080).
3. Wklej zawartość skryptu do głównej pętli.
4. Zapisz urządzenie wirtualne i poczekaj około minuty, 
   możesz obserwować postęp w "debugu".
5. Jeśli wszystko poszło ok, odświeżając stronę zobaczysz 
   gotowe urządzenie do sterowania!

Możesz potem definiować własną listę ulubionych kanałów 
poprzez dodawanie kolejnych przycisków (za przykładowym
Discovery na końcu).
