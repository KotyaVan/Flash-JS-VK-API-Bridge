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
			
			//Если во flash добавляются несколько слушателей на одно событие с одной и тои же функцией обработчиком, то при событии функция будет срабатывать только один раз. И чтобы в функцию перестали приходить события,
			//необходимо отвязаться один раз, а не столько, сколько раз подписывался. Поэтому, если слушатель события с такой функцией обработчика уже зарегестрирован, НЕ нужно сообщать об добавлении нового слушателя JS, 
			//чтобы он не повышал счетчик слушающих события во флэше функции. Смотри реализацию и описания функции clientAPICallBackControl() в JS. 
			if(_vkClientApiEvent[type] == listener){
				//
				return;
			}
			//Слушателя с такой функцией нет
			_vkClientApiEvent[type] = listener;
			//Тут можно было бы полностью реализовать, что реализовано в JS в функции clientAPICallBackControl() - чтобы JS не подписывался на те события, на которые уже подписался
			//И это было бы проще реализовывать и это, наверное, было бы лучшем решением.
			
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
			
			//Проверяем, есть ли ключ. Если нет, выходим из функции. Т.к если данные о удаляении слушателя передатутся в JS, то он уменьшит счетчик слушателей, и может отписаться от события
			//А во флэщ может оставаться другой обработчик, которые слушает это событие
			if(_vkClientApiEvent[type] == null) return;
			//Удаляем ключ - событие и ссылку на функцию слушателя
			delete _vkClientApiEvent[type];
			
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