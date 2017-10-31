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


// В данной модификации удалены варианты с счетчиком уже слушающих событий. Т.к теперь все это реализовано во флэш, и флэш попросит
// подписаться JS на событие, только в том случае, если оно первое во флэш, и удалить, если оно было последнее. 
// В любом случае, вы можете продолжать использовать старую конструкцию, с счетчиками слушателей, - они будут работать.
// С помощью нее можно убедиться, что JS слушатель на событие ставиться один раз в то время, как во флэше можкт быть три слушателя на это событие
var clientAPICallBackFunction = {}; //Записываем ссылку на функцию, которая обрабатывает событие. (Событие - ключ) Только для того, чтобы потом ее удалить

function clientAPICallBackControl(methodName, controlType){

console.log(methodName, controlType);

  if(controlType == "addEventListener"){ // Нужно добавить слушатель
  // Сколько функция будет принимать аргументов, и какого типа неизвестно. Это зависит от метода.
  // Поэтому во флэш будет отправлятся массив аргументов arguments, даже если он пустой
    VK.addCallback(methodName, callBackFunction);
    function callBackFunction() {
      var dataObj = {}; // Объект, которые будет передан во flash
      dataObj.callType = "vkClientApiEvent"; // Данные, нужные flash
      dataObj.methodName = methodName;
      dataObj.value = arguments;
      sendToActionScript(dataObj);
    };
    clientAPICallBackFunction[methodName] = callBackFunction; // Сохраняем сслыку на эту функцию
  } else if (controlType == "removeEventListener"){ //Нужно убрать слушатель
    VK.removeCallback(methodName, clientAPICallBackFunction[methodName]);
  }
}