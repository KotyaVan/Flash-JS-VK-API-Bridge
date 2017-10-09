package ExternalFlash.events {
	import flash.events.Event;
	
	public class CustomEvent extends Event {
		
		public var params:Object;//
		
		//Константы всех событий вк, описаных в документации на 08/10/17.
		public static const ON_APPLICATION_ADDED:String = "onApplicationAdded";
		public static const ON_SETTING_CHANGED:String = "onSettingsChanged";
		public static const ON_REQUEST_SUCCESS:String = "onRequestSuccess";
		public static const ON_REQUEST_CANCEL:String = "onRequestCancel"
		public static const ON_REQUEST_FAIL:String = "onRequestFail";
		public static const ON_BALANCE_CHANGED:String = "onBalanceChanged"
		public static const ON_ORDER_CANCEL:String = "onOrderCancel";
		public static const ON_ORDER_SUCCESS:String = "onOrderSuccess";
		public static const ON_ORDER_FAIL:String = "onOrderFail"
		public static const ON_PROFILE_PHOTO_SAVE:String = "onProfilePhotoSave";
		public static const ON_WINDOW_RESIZED:String = "onWindowResized";
		public static const ON_LOCATION_CHANGED:String = "onLocationChanged";
		public static const ON_WINDOW_BLUR:String = "onWindowBlur";
		public static const ON_WINDOW_FOCUS:String = "onWindowFocus";
		public static const ON_SCROLL_TOP:String = "onScrollTop";
		public static const ON_SCROLL:String = "onScroll";
		public static const ON_TOGGLE_FLASH:String = "onToggleFlash";
		public static const ON_INSTALL_PUSH_SUCCESS:String = "onInstallPushSuccess";
		//Констатанта библиотеки. 
		//Используются при прослушивания информации о окончании инициализации Ei. Инициализация можеть быть не обязательно успешной.
		public static const ON_EI_INIT_END:String = "onEiInitEnd";

		public function CustomEvent(type:String, params:Object, bubbles:Boolean=false, cancelable:Boolean=false) {
			// Вызываю родительский класс
			super(type, bubbles, cancelable);
        	this.params = params;
		}

		//В документации сказано, что при создании customEvent, для его корректной работы необходимо переопределять два метода clone() и toString()
		public override function clone():Event
		{
			return new CustomEvent(type, params, bubbles, cancelable);
		}
		
		public override function toString():String
		{
			return formatToString("CustomEvent", "type", "bubbles", "eventPhase", "params");
		}

	}
	
}
