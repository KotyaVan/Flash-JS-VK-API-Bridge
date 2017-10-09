## Flash-JS-VK-API-Bridge
**Flash-JS-VK-API-Bridge** - посредник для Flash приложений, встроенных в iFrame. Использование данного посредника дает возможность обращаться к методам API соц. сети Вконтакте из AS3.

**Плюсы работы через данного посредника:**
* Работа приложений в Google Chrome. Google Chrome блокирует работу предоставленного соц. сетью [Flash SDK](https://vk.com/dev/Flash_SDK) на основе [LocalConnection'a](http://help.adobe.com/ru_RU/FlashPlatform/reference/actionscript/3/flash/net/LocalConnection.html)
* Возможность добавить HTML контент к приложению и другие плюшки. Так же, например, можно добавить [виджеты.](https://vk.com/dev/widgets_for_sites)

### Принцип работы посредника 
*Краткое описание:*
Принцип работы посредника устроен на вызове функции JS из Flash'a и наоборот. Это достигается за счёт методов класса [**ExternalInterface.**](http://help.adobe.com/ru_RU/FlashPlatform/reference/actionscript/3/flash/external/ExternalInterface.html)
В свою очередь, JS взаимодействуют с [**JavaScript SDK**](https://vk.com/dev/Javascript_SDK), которую предоставляет социальная сеть. 
В html страницу объект-flash встраивается по средствам [swfObject.](https://habrahabr.ru/post/31615/)

### Подключение во Flash

```as
//as code

```
