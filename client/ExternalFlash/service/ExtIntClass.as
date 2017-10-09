package ExternalFlash.service {
	import ExternalFlash.vk.*;
	import ExternalFlash.events.CustomEvent;
	
	import flash.events.*;
	import flash.text.TextField;
	import flash.external.ExternalInterface;
	import flash.utils.Timer;
	
	public class ExtIntClass {
		
		private var _currentState:int;//Переменная отражающая текущее состояние
		private var _notWorkReason:int;//Причина, по которой не работает EI
		private var _checkingTimerJS:Timer;
		private var _checkingTimerVkAPI:Timer;
				
		private var _vkMethods:VkMethods;
		private var _vkClientApi:VkClientApi;
		private var _dispatchFunction:Function;
						
		//Статусы currentState
		private const NOT_STARTING:int = 0;//0 - не запущен 
		private const INITIALIZATION:int = 1;//1 - инициализация (Проверка ExternalInterface.available);
		private const CHECKING_READY_JS:int = 2;//2 - проверка готовности js
		private const TIMER_WORK:int = 3;//3 - js не был готов, запустили таймер, таймер работает
		private const ADDING_CALLBACK:int = 4;//4 - flash добавляет callback function
		private const READINESS_REPORT:int = 5;//5 - сообщает о готовности flash ролика принимать и отправлять данные
		private const CHECKING_READY_VK_API:int = 6;//6 - проверка готовности vk api
		public const WORKING:int = 7;//7 - готов к обмену информации
		public const NOT_WORK:int = 10;//10 - не работает
		//Причина, по которой ExternalInterface не работает
		private const NO_ERRORS:int = 0;//0 - ошибок нет
		private const NOT_AVAILABLE_IN_CONTAINER:int = 1;//1 - он не доступен в данном контейнере (ExternalInterface.available = false)
		private const IO_CALL_ERROR:int = 2;//2 - ошибка входящих/исходящих вызовов, (!) сюда так же, могут попасть ошибки по другой причине
		private const SECURITY_ERROR:int = 3;//3 - ошибка безопасности, сработана при попытки использовать методы addCallback, call
		private const CONNECT_ERROR:int = 4;//4 - таймер отработал поставленное время, а js так и не был готов
		private const VK_API_ERROR:int = 5;//5 - ошибка VK Api, либо за время ожидание он так и не был готов 
		
		public function ExtIntClass(vkMethodSendParams:Array, dispatchFunction:Function) {
			//
			_vkMethods = new VkMethods(vkMethodSendParams);
			_vkClientApi = new VkClientApi(dispatchFunction);
			_dispatchFunction = dispatchFunction;
			//
			//Указываем время, сколько будет работать таймер
			_checkingTimerJS = new Timer(100, 10);//Указываем, сколько максимально времени и раз будет проверяться готовность JS
			_checkingTimerVkAPI = new Timer(100, 100);//Указываем, сколько максимально времени и раз будет проверяться готовность Vk Api
			//Устанавливаем статус подключения
			setStatus(NOT_STARTING, NO_ERRORS);
			//Вызываем функцию инициализации
			ExtInterfaceInit();
		}
	
		//Функция инициализации
		private function ExtInterfaceInit():void
		{
			//
			//Устанавливаем статус соединения
			setStatus(INITIALIZATION, NO_ERRORS);
			//Проверяем, доступен ли EI в данном контейнере
			if (ExternalInterface.available) {//Да, доступен
				//
				//Вызываем функцию проверки, готов ли JS к работе
				checkJavaScriptReady();
			} else {// Нет, не доступен
				//
				//Устанавливаем статус подключения
				setStatus(NOT_WORK, NOT_AVAILABLE_IN_CONTAINER);
			}
		}

		//Фунция проверки готовности JS, может вызываться без аргументов, может вызываться с аргументов, таймером
		private function checkJavaScriptReady(event:TimerEvent = null):void
		{
			if(event == null) {
				//
				//Если функция вызывается без аргумента, то она вызвается в первые, поэтому устанавливаем статус подключения
				setStatus(CHECKING_READY_JS, NO_ERRORS);
			}
			//Пробуем проверить, готов ли JS к обмену информацией 
			try{
				//Вызываем функцию из JS и записываем ее значение
				var isReady:Boolean = ExternalInterface.call("isReady", "JS");
				if(isReady) { //Готов
					//
					//Проверяем, вызвана ли функция, как события таймера
					if(event != null)
					{
						_checkingTimerJS.removeEventListener(TimerEvent.TIMER, checkJavaScriptReady);
						_checkingTimerJS.removeEventListener(TimerEvent.TIMER_COMPLETE, checkJavaScriptReady);
					}
					//Добавить callback, функцию, в которую будут приходить сообщения от JS
					addJSCallBackFunction();
					//Сообщить о том что флэш готов
					showReadinessAS();
					//Проверяем готовность к работе Api Vk
					checkVkApiReady();
				} else { //Не готов
					if(event == null) {
						_checkingTimerJS.start();
						_checkingTimerJS.addEventListener(TimerEvent.TIMER, checkJavaScriptReady);
						_checkingTimerJS.addEventListener(TimerEvent.TIMER_COMPLETE, checkJavaScriptReady);
						//
						//
						setStatus(TIMER_WORK, NO_ERRORS);//Устанавливаем статус соединения
					} else if(event.type == TimerEvent.TIMER){
						//
					} else if(event.type == TimerEvent.TIMER_COMPLETE){
						//
						setStatus(NOT_WORK, CONNECT_ERROR);//Устанавливаем статус подключения
					}
				}
			} catch (error:SecurityError) {
				//
				setStatus(NOT_WORK, SECURITY_ERROR);//Устанавливаем статус подключения
			} catch (error:Error) {
				//
				setStatus(NOT_WORK, IO_CALL_ERROR);//Устанавливаем статус подключения
			}
		}
		
		//Проверка готовности Vk Api
		private function checkVkApiReady(event:TimerEvent = null):void
		{
			//Если функция вызывается без аргумента, то она вызвается в первые, поэтому устанавливаем статус подключения
			if(event == null) {
				//
				setStatus(CHECKING_READY_VK_API, NO_ERRORS);
			} else {
				//Функцию вызывал таймер, если это сообщение, о том, что таймер закончился, пишем, как ошибку
				//
				if(event.type == TimerEvent.TIMER_COMPLETE)
				{
					setStatus(NOT_WORK, VK_API_ERROR);//Устанавливаем статус подключения
					return;//Выходим из функции
				}
			}
			
			//Получаем информацию о состоянии готовности Vk Api
			var isReady:int = ExternalInterface.call("isReady", "API");
			
			//Если значение isReady появилось (стало 1 или 2), и при это работал таймер, останавливаем его
			if(isReady != 0 && event != null){
				_checkingTimerVkAPI.removeEventListener(TimerEvent.TIMER, checkVkApiReady);
				_checkingTimerVkAPI.removeEventListener(TimerEvent.TIMER_COMPLETE, checkVkApiReady);
				_checkingTimerVkAPI.stop();
			}

			//Проверяем полученное значение
			if(isReady == 0){
				//Полученное значение 0, если это проверка не по таймеру, то ставим его
				if(event == null){
					_checkingTimerVkAPI.addEventListener(TimerEvent.TIMER, checkVkApiReady);
					_checkingTimerVkAPI.addEventListener(TimerEvent.TIMER_COMPLETE, checkVkApiReady);
					_checkingTimerVkAPI.start();
				}
			}else if(isReady == 1){
				//Vk API готов, слушателе убрали выше, если они были
				setStatus(WORKING, NO_ERRORS);//Устанавливаем статус подключения
			}else if(isReady == 2){
				//Ошибка Vk API
				setStatus(NOT_WORK, VK_API_ERROR);//Устанавливаем статус подключения
			}
		}
		
		//Добавляем функцию, которую будет видеть JS, после этого возможно передача данных по EI
		private function addJSCallBackFunction():void
		{
			//
			setStatus(ADDING_CALLBACK, NO_ERRORS);//Устанавливаем статус соединения
			//
			ExternalInterface.addCallback("sendToActionScript", receivedFromJavaScript);
		}
		
		//Отсылаем JS информацию, что AS готов к связи. Так же обновит статус подключения во флэш
		private function showReadinessAS():void
		{
			//
			ExternalInterface.call("readySet", "AS");
			//
			setStatus(READINESS_REPORT, NO_ERRORS);//Устанавливаем статус соединения
		}
		
		//Отправить в JS
		public function sendToJavaScript(value:Object):void
		{	
			//
			ExternalInterface.call("sendToJavaScript", value);
		}
		
		//Получила из JS
		public function receivedFromJavaScript(value:Object):void {
			//
			if(value.callType == "vkMethodCall"){
				_vkMethods.reviewData(value);
			} else if(value.callType == "vkClientApiEvent"){
				_vkClientApi.reviewData(value);
			} else {
				//Полученно что-то неизвестное
			}
		}		
		
		//Устанавливает статус подключения
		private function setStatus(currentState:int, notWorkReason:int):void
		{
			if(currentState == WORKING)
			{
				_dispatchFunction(CustomEvent.ON_EI_INIT_END, {connectState:"WORKING"});
			} else if(currentState == NOT_WORK) {
				_dispatchFunction(CustomEvent.ON_EI_INIT_END, {connectState:"NOT_WORKING"});
			}
			
			_currentState = currentState;
			_notWorkReason = notWorkReason;
		}
		
		//Показывает статус подключения
		public function getStatus():Array
		{
			return new Array(_currentState, _notWorkReason);
		}
		
	}
	
}
