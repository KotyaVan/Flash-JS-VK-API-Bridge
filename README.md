## Flash-JS-VK-API-Bridge
**Flash-JS-VK-API-Bridge** - посредник для Flash приложений, встроенных в iFrame. Использование данного посредника дает возможность обращаться к методам API соц. сети Вконтакте из AS3.

**Плюсы работы через данного посредника:**
* Работа приложений в Google Chrome. Google Chrome блокирует работу предоставленного соц. сетью [Flash SDK](https://vk.com/dev/Flash_SDK) на основе [LocalConnection'a](http://help.adobe.com/ru_RU/FlashPlatform/reference/actionscript/3/flash/net/LocalConnection.html)
* Возможность добавить HTML контент к приложению и другие плюшки. Так же, например, можно добавить [виджеты.](https://vk.com/dev/widgets_for_sites)

### Принцип работы посредника 
*Краткое описание:*
Принцип работы посредника устроен на вызове функции JS из Flash'a и наоборот. Это достигается за счёт методов класса [**ExternalInterface.**](http://help.adobe.com/ru_RU/FlashPlatform/reference/actionscript/3/flash/external/ExternalInterface.html)
В свою очередь, JS взаимодействуют с [**JavaScript SDK**](https://vk.com/dev/Javascript_SDK), которую предоставляет социальная сеть. 
В html страницу объект-flash встраивается по средствам [**swfObject.**](https://habrahabr.ru/post/31615/)

### Подключение во Flash

Подключите к вашему проекту необходимые классы:
```as
//as code
import ExternalFlash.APIConnection;
import ExternalFlash.events.CustomEvent;
```
Если Вам так же необходимо создания кнопок, со стилем социальной сети, не забудьте подключить данный класс:

```as
//as code
import ExternalFlash.ui.VKButton
```
Создайте экземпляр класса *APIConnection*, проверьте готов ли посредник к работе. В случае если посредник еще не готов, подпишитесь на событие *CustomEvent.ON_EI_INIT_END*. Начинайте работать с посредником только после того, как он будет готов к работе. В противном случае, он может работать не корректно.
**Пример** создания экземпляра, с проверкой на инициализацию:
```as
//as code
//Создаем экземпляр класса APIConnection
_VK = new APIConnection();

//Перед тем, как делать запросы, добавлять слушатели и т.д. Необходимо обязательно убедится, что посредник уже инициализировался.
//Иначе, посредник будет работать некорректно. Информация о инициализации может быть трех типов:
if(_VK.eiConnectStatus == "WORKING"){
  //Посредник инциализировался, все работает. Только теперь можем работать с API
  //Тут можно вызывать функцию, которая начнет работать с методами API
} else if(_VK.eiConnectStatus == "NOT_WORK"){
  //Посредник не работает по какой либо причине.Это окончательный статус, он не изменится. Причина непоказывается, но если вы захотите сделать ее вывод, Вы можете посмотреть в классе ExtIntClass список причин, и выводить их оттуда
} else if(_VK.eiConnectStatus == "CONNECTION"){
  //Посредник еще не загрузился. В этом случае надо поставить слушатель на экз. класса и слушать событие CustomEvent.ON_EI_INIT_END
  //Событие приходит вместе с параметром connectState. Может быть WORKING - значить посредник инициализировался. NOT_WORKING - посредник не будет работать.
  _VK.addEventListener(CustomEvent.ON_EI_INIT_END, function (event:CustomEvent){
      if(event.params.connectState == "WORKING"){
        //Посредник инциализировался, все работает. Только теперь можем работать с API
        //Тут можно вызывать функцию, которая начнет работать с методами API
      }else{
        //Посредник не работает
      }
      _VK.removeEventListener(CustomEvent.ON_EI_INIT_END, arguments.callee);
  })
}
```

