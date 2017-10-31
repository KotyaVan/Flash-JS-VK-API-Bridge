package ExternalFlash
{
	import ExternalFlash.service.ExtIntClass;
	import ExternalFlash.events.CustomEvent;
	
	import flash.events.EventDispatcher;

	public class APIConnection extends EventDispatcher
	{
		private var _eic:ExtIntClass;//Класс, контролирующий работу с IE.
		
		private var _vkMethodCallRegister:Array = new Array();//Массив, содержит список запросов, которые были сделаны, но ответа не получили (ещё). Заносяться туда перед передачей данных в
		//JS, и удаляются после получения и вызова callback функции.
		private var _vkClientEventRegister:Array = new Array();//Массив, содержит в себе объекты. Значения объекта - имя события, ссылка на слушающую функцию. Необходим для того, чтобы не подписываться в JS
		//на событие, которое уже прослушиватеся, и не отписываться от события, которое слушают другие функции
		private var _vkClientApiEvent:Object = new Object();//Объект, ключи которого события VK, на которые подписывается флэшка. Создан, с целью того, чтобы несколько раз не просить JS
		//подписаться на одно и тоже событие
		
		public function APIConnection()
		{
			_eic = new ExtIntClass(_vkMethodCallRegister, dispatchFunction);
		}
		
		//Вызов метода ВК
		public function api(methodName:String, methodParams:Object = null, onSuccessFunction:Function = null, onErrorFunction:Function = null):void
		{
			//Записываем всю необходимую информацию о вызове метода, чтобы занести ее в массив
			var registerParams:Object = new Object();
			registerParams.onSuccessFunction = onSuccessFunction;
			registerParams.onErrorFunction = onErrorFunction;
			registerParams.callId = _vkMethodCallRegister.length;
			//Эти данные сохранятся в массив, т.к нужно хранить callBack функции
			_vkMethodCallRegister.push(registerParams);
			
			//Записываем всю необходимую информацию, чтобы отправить ее дальше в JS
			var sendParams:Object = new Object();
			sendParams.methodName = methodName;
			sendParams.methodParams = methodParams;
			sendParams.callType = "vkMethodCall";
			sendParams.callId = registerParams.callId;
			//
			_eic.sendToJavaScript(sendParams);
		}
		
		//Вывов Client Api. Вызов может содержать разное кол-во параметров, поэтому используется ...rest
		public function callMethod(methodName:String, ...methodParams):void
		{
			//У Client API нет callBack'ов, поэтому необходимости записывать какие-то данные нет
			var sendParams:Object = new Object();
			sendParams.methodName = methodName;
			sendParams.methodParams = methodParams;
			sendParams.callType = "vkClientApiCall";
			//
			_eic.sendToJavaScript(sendParams);
		}
		
		//Переопределяю функцию addEventListener. Т.к помимо привязки к собятиям, нужно подписаться на собяти в JS, тоесть передать данные JS
		override public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void
		{
			super.addEventListener(type, listener);
			
			//Если подписывается на события этой библиотеки, данные в JS отправлян не нужно
			if(type == CustomEvent.ON_EI_INIT_END){
				return;
			}
			
/*			//Если во flash добавляются несколько слушателей на одно событие с одной и тои же функцией обработчиком, то при событии функция будет срабатывать только один раз. И чтобы в функцию перестали приходить события,
			//необходимо отвязаться один раз, а не столько, сколько раз подписывался. Поэтому, если слушатель события с такой функцией обработчика уже зарегестрирован, НЕ нужно сообщать об добавлении нового слушателя JS			
			var eventListenerObj:Object = {eventName:type, listenerFunction:listener};
			for(var i:int = 0; i < _vkClientEventRegister.length; i++){
				if((_vkClientEventRegister[i].eventName == eventListenerObj.eventName) && (_vkClientEventRegister[i].listenerFunction == eventListenerObj.listenerFunction)){
					//Такое событие уже слушается, причем с такой же функией
					return;
				}
				
				if(_vkClientEventRegister[i].eventName == eventListenerObj.eventName){
					//Такое событие уже слушается, но с другим функцией обработчика
					_vkClientEventRegister.push(eventListenerObj);
					return;
				}
			}
			
			_vkClientEventRegister.push(eventListenerObj);
			*/
			
			if(_vkClientApiEvent[type] == null)//На такое событие не подписаны
			{
				_vkClientApiEvent[type] = [];//Make array
				
				_vkClientApiEvent[type].push({eventType:type, eventListener:listener})
			}
			else //подписаны
			{
				for(var i:int = 0; i < _vkClientApiEvent[type].length; i++)
				{
					if(_vkClientApiEvent[type][i].eventListener == listener){
						//Уже есть
						return;
					}
				}
				
				//Если уже на это событие подписаны
				if(_vkClientApiEvent[type].length > 0){
					_vkClientApiEvent[type].push({eventType:type, eventListener:listener});
					return;
				} else {
					_vkClientApiEvent[type].push({eventType:type, eventListener:listener});
				}
				
			}
			
			var sendParams:Object = new Object();
			sendParams.methodName = type;
			sendParams.controlType = "addEventListener";
			sendParams.callType = "vkClientApiEvent";
			//
			_eic.sendToJavaScript(sendParams);
		}
		
		//Переопределяю функцию removeEventListener по той же причине
		override public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void
		{
			super.removeEventListener(type, listener);
			
			//Если подписывается на события этой библиотеки, данные в JS отправлян не нужно
			if(type == CustomEvent.ON_EI_INIT_END){
				return;
			}
			
/*			var eventListenerObj:Object = {eventName:type, listenerFunction:listener};
			var eventListenersCount:int = 0;
			var eventListenerWas:Boolean;
			for(var j:int = 0; j < _vkClientEventRegister.length; j++){
				if((_vkClientEventRegister[j].eventName == eventListenerObj.eventName) && (_vkClientEventRegister[j].listenerFunction == eventListenerObj.listenerFunction)){
					//
					_vkClientEventRegister.splice(j, 1);
					eventListenerWas = true;
					break;
				}
			}
			
			for(var i:int = 0; i < _vkClientEventRegister.length; i++){
				if(_vkClientEventRegister[i].eventName == eventListenerObj.eventName){
					eventListenersCount++;
				}
			}
						
			if(eventListenersCount > 0) return;
			if(!eventListenerWas) return;*/
			
			if(_vkClientApiEvent[type] == null){
				//Таких событии не слушаем
				return;
			} else {
				
				if(_vkClientApiEvent[type].length == 0) return;
				
				for(var i:int = 0; i < _vkClientApiEvent[type].length; i++)
				{
					if(_vkClientApiEvent[type][i].eventListener == listener)
					{
						_vkClientApiEvent[type].splice(i, 1);
					}
				}
				
				//throw new Error(_vkClientApiEvent[type].length);
				if(_vkClientApiEvent[type].length > 0) return;
			}
			
			var sendParams:Object = new Object();
			sendParams.methodName = type;
			sendParams.controlType = "removeEventListener";
			sendParams.callType = "vkClientApiEvent";
			//
			_eic.sendToJavaScript(sendParams);
		}
		
		//Функция, которая будет вызываться в VkClientApi в случае, если в JS сработало событие, на которое оно подписовалось
		//В свою очередь, функция будет генерировать событие. Эту задачу можно было бы решить другим образом. Т.к функции addEventListener/removeEventListener переопределялись
		//можно было при вызове их сохранять/удалять ссылку на переданную функции, и вызывать ее. Обошлись бы без генератора событий.
		//Помимо VkClientApi функция вызывается в ExtIntClass, когда происходит успешная инициализация, или ошибка инициализации
		public function dispatchFunction(eventName:String, eventParams:Object = null):void
		{
			dispatchEvent(new CustomEvent(eventName, eventParams));
		}
		
		//Возращает текущее состояния иницилизации EI (включая JS, Vk Api)
		public function get eiConnectStatus():String
		{
			var connectStatus:Array = _eic.getStatus();
			if(connectStatus[0] == _eic.WORKING){
				return "WORKING";
			}else if(connectStatus[0] == _eic.NOT_WORK){
				return "NOT_WORK";
			}else{
				return "CONNECTION";
			}
		}
	}
}