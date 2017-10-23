function vkApiInit(){
VK.init(function() { 
     // API initialization succeeded 
    readySet("API", false);
  }, function() { 
     // API initialization failed 
    readySet("API", true);
}, '5.68'); 
}

//Вызов метода Vk Api
function apiMethods(methodName, methodParams, methodCallId, methodType){
  // Проверяем, инициализировался ли vkApi
  if(apiReady){ //Да
    VK.api(methodName, methodParams, function (data) {
      data.callId = methodCallId;
      data.callType = methodType;
      sendToActionScript(data);
    });
  } else { //Нет
    //В таком случае, отправится ошибка, о том, что Vk Api не инициализирован.
    var dataObj = {};
    dataObj.callId = methodCallId;
    dataObj.callType = methodType;
    dataObj.error = {error_code:1000, error_msg:"Vk API not init in JS."};
    sendToActionScript(dataObj);
  }
}

//Вызов Client API
function clientAPI(methodName, methodParams){
  // Проверяем, инициализировался ли vkApi
  if(apiReady){ //Да
    // Из-за использования apply, необходимо, чтобы все параметры были одним единным массивом
    // methodParams - уже массив. Из flash'ки он уже передается как массив.
    var argArray = methodParams; // Поэтому его беру за основу
    argArray.unshift(methodName); // И добавляю к нему первый аргумент
    // Из-за того, что не знаю, сколько будет параметров, использую apply
    VK.callMethod.apply(null, argArray);
  } else { //Не инициализирован
    // Но во flash'e нет, и не должно быть, функции, которое получит callBack по данному событию.
    // Поэтому просто выведем сообщение в консоль
    console.log("Vk API not init");
  }
}

// Объект, ключом которого будет название событие, значением - ссылка на функцию, которая обрабатывает событие
// При регистрировании нескольких функции на одно событие в JS, срабатывать будет только последняя.
// Поэтому важно не допустить, чтобы слушатель на событие, которые уже есть, регистрировался еще раз.
// При передаче информации о событии во флэш, в нем, о событии будет получать инфрмацию каждый подписавшийся слушатель
// Если названия события будет переданно с ошибкой, то вк на это никак не отреагирует. Стоит обращать внимание на это.
// Во flash будут созданы констаны с названиями, но все равно это не защитит от возможности ошибок, т.к проверки на правильности не будет
var clientAPICallBackFunction = {};
// Считает кол-во, сколько было добавленно слушателей из flash. Чтобы, когда из flash начнут отписываться от событий,
// в JS отписка от события произошла в только случае, если это был последнии отписавшийся слушатель
// Ключ - название события, значения - кол-во подписок.
var clientAPICallBackCounter = {};
// 
function clientAPICallBackControl(methodName, controlType){
  // Если vk Api не было инициализировано, то слушатель не будет прикреплен. А flash будет ждать событие. Поэтому в случае
  // в этом случае, пошлем в функцию сообщение, о том, что, слушатель не был добавлен. 
  // Вообще, описанное никак недолжно происходить, т.к. флэш библиотека начнет посылать запросы только после инициализации Vk API. 
  // if(!apiReady){
  //   // 
  //   var dataObj = {}; // Объект, которые будет передан во flash
  //   dataObj.callType = "vkClientApiEvent"; // Данные, нужные flash
  //   dataObj.methodName = methodName;
  //   dataObj.error = {error_code:1000, error_msg:"Vk API not init in JS, listener not added."};

  //   sendToActionScript(dataObj);
  //   return;
  // }
  if(controlType == "addEventListener"){ // Нужно добавить слушатель
    // Проверяем, слушается ли уже эти событие
    if(clientAPICallBackFunction[methodName] == null){ // Если нет
      // То ставим слушатель
      // Сколько функция будет принимать аргументов, и какого типа неизвестно. Это зависит от метода.
      // Поэтому во флэш будет отправлятся массив аргументов arguments, даже если он пустой
      VK.addCallback(methodName, callBackFunction);
      console.log(arguments);
      function callBackFunction() {
        var dataObj = {}; // Объект, которые будет передан во flash
        dataObj.callType = "vkClientApiEvent"; // Данные, нужные flash
        dataObj.methodName = methodName;
        dataObj.controlType = controlType;
        dataObj.value = arguments;
        console.log(arguments);
        sendToActionScript(dataObj);
      };

      clientAPICallBackFunction[methodName] = callBackFunction; // Сохраняем сслыку на эту функцию
      clientAPICallBackCounter[methodName] = 1; //Ставим счетик в одно использование, для чего нужны счетчики было описано выше

    } else {
      clientAPICallBackCounter[methodName]++; //Добавляем счетчик плюс одно использование
    }
  } else if (controlType == "removeEventListener"){ //Нужно убрать слушатель
    if(clientAPICallBackFunction[methodName] != null){ //Есть ли слушатель на такое событие есть
      // Уменьшаем счетчик использования
      clientAPICallBackCounter[methodName]--;
      // Смотрим, используется ли еще 
      if(clientAPICallBackCounter[methodName] == 0){
        // Если нет, то удаляем
        VK.removeCallback(methodName, clientAPICallBackFunction[methodName]);

        // Если это было последнее использование то удаляем ключи - значения из объектов
        delete clientAPICallBackFunction[methodName];
        delete clientAPICallBackCounter[methodName];
      }
    } else {
      // Такое событие не слушается
    }
  }
}