package 
{
	import ExternalFlash.APIConnection;
	import ExternalFlash.events.CustomEvent;
	import ExternalFlash.ui.VKButton
	
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.text.*;
	import flash.events.MouseEvent;

	public class ExtIntProf extends MovieClip{

		private var _VK:APIConnection;
		private var _flashVars: Object = stage.loaderInfo.parameters as Object;
		
		private var textDescriptions:TextField = new TextField();
		private var settingsBtn:VKButton = new VKButton("Настройки");
		private var wallPostBtn:VKButton = new VKButton("На стену");
		private var inviteFriendsBtn:VKButton = new VKButton("Пригласить друзей");
		private var paymentsBtn:VKButton = new VKButton("Платежка");
		private var userDataGet:VKButton = new VKButton("users.get");
		private var addEvListOnWindowBlur:VKButton = new VKButton("Доб. слуш. onSettingsChangedEvent");
		private var removeEvListOnWindowBlur:VKButton = new VKButton("Уд. слуш. onSettingsChangedEvent");

		public function ExtIntProf(){
		
			//Настройка элментов, которые будут отображаться на сцене
			//Текстового поля
			textDescriptions.x = 26;
			textDescriptions.y = 80;
			textDescriptions.width = 500;
			textDescriptions.height = 300;
			textDescriptions.border = true;
			textDescriptions.borderColor = 0xDAE2E8;
			textDescriptions.background = true;
			textDescriptions.backgroundColor = 0xFFFFFF;
			textDescriptions.embedFonts = false;
			var textFormat:TextFormat = new TextFormat();
			textFormat.font = "Tahoma";
			textFormat.color = 0x000000;
			textFormat.size = 11;
			textDescriptions.defaultTextFormat = textFormat;
			addChild(textDescriptions);
			//Кнопки с настройками
		  	settingsBtn.x = 35;
		  	settingsBtn.y = 10;
		  	addChild(settingsBtn);
			//Пост на стену
		  	wallPostBtn.x = 125;
		  	wallPostBtn.y = 10;
		  	addChild(wallPostBtn);
			//Пригласить друзей
			inviteFriendsBtn.x = 205;
			inviteFriendsBtn.y = 10;
			addChild(inviteFriendsBtn);
			//Платежка
			paymentsBtn.x = 345;
			paymentsBtn.y = 10;
			addChild(paymentsBtn);
			//Данные пользвателя 
			userDataGet.x = 430;
			userDataGet.y = 10;
			addChild(userDataGet);
			//Добавить слушатель на onWindowBlur
			addEvListOnWindowBlur.x = 30;
			addEvListOnWindowBlur.y = 40;
			addChild(addEvListOnWindowBlur);
			//Удалить слушатель с onWindowBlur
			removeEvListOnWindowBlur.x = 290;
			removeEvListOnWindowBlur.y = 40;
			addChild(removeEvListOnWindowBlur);
			
			//Создаем экземпляр класса, который работает с EI и соответственно с VkAPI
			_VK = new APIConnection();
			
			//!!!
			//Перед тем, как делать запросы, добавлять слушатели и т.д. Необходимо обязательно убедится, что посредник EI и VkApi в JS уже инициализировались
			//Иначе, посредник будет работать некорректно. Информация о инициализации может быть трех типов:
			if(_VK.eiConnectStatus == "WORKING"){
				//Посредник инциализировался, все работает. Можно делать запросы.
				textDescriptions.appendText("Посредник ExternalInterface работает. Можно работать с API.\n");
				//Только теперь можем работать с API
				eiSuccessInit();
			} else if(_VK.eiConnectStatus == "NOT_WORK"){
				//Посредник не работает по какой либо причине.Это окончательный статус, он не изменится. Причина непоказывается, но при желании можете вывести ее из экз. ExtIntClass
				textDescriptions.appendText("Посредник ExternalInterface не работает.\n");
			} else if(_VK.eiConnectStatus == "CONNECTION"){
				//Посредник еще не загрузился. В этом случае надо поставить слушатель на экз. _VK и слушать событие CustomEvent.ON_EI_INIT_END
				textDescriptions.appendText("Посредник ExternalInterface не загрузился.\n");
				//Событие приходит вместе с параметром connectState. Может быть WORKING - значить посредник инициализировался. NOT_WORK - посредник не будет работать
				_VK.addEventListener(CustomEvent.ON_EI_INIT_END, function (event:CustomEvent){
						if(event.params.connectState == "WORKING"){
							textDescriptions.appendText("Посредник ExternalInterface загрузился. Можно работать с API.\n");
							//Только теперь можем работать с API
							eiSuccessInit();
						}else{
							textDescriptions.appendText("Посредник ExternalInterface не работает.\n");
						}
						_VK.removeEventListener(CustomEvent.ON_EI_INIT_END, arguments.callee);
				})
			}
			
		}
		
		private function eiSuccessInit():void
		{
			//Данные пользователя из flashVars доступны сразу, если они есть. Дожидаться иниц посредника, чтобы работать с ними, не обязательно.
			textDescriptions.appendText("Ваши данные из flashVars\n");
			textDescriptions.appendText("api_id = " + _flashVars['api_id'] + "\n");
			textDescriptions.appendText("viewer_id = " + _flashVars['viewer_id'] + "\n");
			textDescriptions.appendText("sid = " + _flashVars['sid'] + "\n");
			textDescriptions.appendText("secret = " + _flashVars['secret'] + "\n");
			
			settingsBtn.addEventListener(MouseEvent.CLICK, function(event:MouseEvent){
				_VK.callMethod("showSettingsBox", 256);
			})
			
			wallPostBtn.addEventListener(MouseEvent.CLICK, function(event:MouseEvent){
				 _VK.api("wall.post", {"message": "Hello!"}, function (data:Object) {
					textDescriptions.appendText("После вызова wall.post получены параметры: " + data.post_id);
				})
			})
			
			inviteFriendsBtn.addEventListener(MouseEvent.CLICK, function(event:MouseEvent){
				 _VK.callMethod("showInviteBox");
			})
			
			paymentsBtn.addEventListener(MouseEvent.CLICK, function(event:MouseEvent){
				 _VK.callMethod("showOrderBox", {type:"item", item:"item"});
			})
			
			userDataGet.addEventListener(MouseEvent.CLICK, function(event:MouseEvent){
				_VK.api("users.get", {}, function(data:Object){
					textDescriptions.appendText("Данные получены, Вы: " + data[0].first_name + "\n");
					}, function(data:Object){
					textDescriptions.appendText("Ошибка при запросе, Код ошибки: " + data.error_code + "\n");
				});
			});
			
			addEvListOnWindowBlur.addEventListener(MouseEvent.CLICK, function(event:MouseEvent){
				textDescriptions.appendText("Добавлен слушатель onSettingsChanged \n");
				_VK.addEventListener("onSettingsChanged", onSettingsChangedEvent);
			})
			
			removeEvListOnWindowBlur.addEventListener(MouseEvent.CLICK, function(event:MouseEvent){
				textDescriptions.appendText("Удален слушатель onSettingsChanged \n");
				_VK.removeEventListener("onSettingsChanged", onSettingsChangedEvent);
			})
		}
		
		private function onSettingsChangedEvent(event:CustomEvent){
			textDescriptions.appendText("Произошло событие onSettingsChangedEvent, переданный параметр Settings: " + event.params[0] + "\n");
		}
		
	}

}
