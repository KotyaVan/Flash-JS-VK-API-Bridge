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
		private var _vkClientEventRegister:Object = new Object();//Объект, ключи которого события VK, на которые подписывается флэшка. Значение - массив, с ссылками на слушающие функции. Создан для
		//того, чтобы в JS неподписывались на события, которые уже и так слушают. И не отписывался в JS от событий, слушатели которых еще есть
		
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
			
			//Если подписывается на события этой библиотеки, данные в JS отправлять не нужно
			if(type == CustomEvent.ON_EI_INIT_END){
				return;
			}
			
			//Проверка, нужно ли подписываться на это событие в JS VK API
			//Если массив функции с таким событием
			if(_vkClientEventRegister[type] == null)//Нет, на такое событие ранее не подписывались
			{
				_vkClientEventRegister[type] = [];//
				_vkClientEventRegister[type].push(listener)//Добавляем ссылку на функцию в массив функции этого события
			}
			else //Как минимум, это события слушали раннее
			{
				//Перебираем все функции обработчики, подписанные на это событие, с целью найти эту же функцию обработчик, слушающее это же событие
				for(var i:int = 0; i < _vkClientEventRegister[type].length; i++)
				{
					if(_vkClientEventRegister[type][i] == listener){
						//Если во flash добавляются несколько слушателей на одно событие с одной и тои же функцией обработчиком, то при событии, функция будет срабатывать только один раз. И чтобы в функцию перестали приходить события,
						//необходимо отписаться один раз, а не столько, сколько раз подписывался. Поэтому, если слушатель события с такой функцией обработчика уже зарегестрирован, НЕ нужно сообщать об добавлении нового слушателя JS,
						//и вообще записывать его в массив, т.к чтобы от него отписаться, достаточно это сделать один раз
						
						//Это событие уже слушает данная функция обработчик
						return;//Никаких данных отправлять JS не надо, выходим из функции
					}
				}
				//Подписаны ли на это событие сейчас
				if(_vkClientEventRegister[type].length > 0){
					//Да, подписаны
					_vkClientEventRegister[type].push(listener);//Сохраняем ссылку на функцию обработчик
					return;//Данные JS передавать не нужно, выходим из функции
				} else {
					//На данные момент на событие не подписаны
					_vkClientEventRegister[type].push(listener);//Записываем ссылку на функцию и продолжаем. Ниже данные будет переданы в JS
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
			
			//Если отписывается от события этой библиотеки, данные в JS отправлян не нужно
			if(type == CustomEvent.ON_EI_INIT_END){
				return;
			}
			
			//Проверка того, нужно дли отписываться от данного события в JS
			if(_vkClientEventRegister[type] == null){
				//На такие события не подписывались, отписываться не от чего
				return;//Передавать данные JS не нужно
			} else {
				//Функции обработчиков на этом событии и так нет
				if(_vkClientEventRegister[type].length == 0) return;
				//Перебираем весь массив данного события, в поиске этой функции обработчика, чтобы ее удалить
				for(var i:int = 0; i < _vkClientEventRegister[type].length; i++)
				{
					if(_vkClientEventRegister[type][i] == listener)
					{
						_vkClientEventRegister[type].splice(i, 1);
					}
				}
				//
				if(_vkClientEventRegister[type].length > 0) return;//Это событие продолжают слушать, в JS отписывать не надо
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