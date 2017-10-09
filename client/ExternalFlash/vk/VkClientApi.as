package ExternalFlash.vk
{
	public class VkClientApi
	{
		private var _dispatchFunction:Function;
		
		public function VkClientApi(dispatchFunction:Function)
		{
			// constructor code
			_dispatchFunction = dispatchFunction;
		}
		
		//Произошло событие Client Api, на которое подписано приложение
		public function reviewData(data:Object)
		{
			_dispatchFunction(data.methodName, data.value);
		}

	}

}