package ExternalFlash.vk
{
	public class VkMethods
	{
		private var _vkMethodSendParams:Array;

		public function VkMethods(vkMethodSendParams:Array)
		{
			// constructor code
			_vkMethodSendParams = vkMethodSendParams;
		}


		//Смотрим, что пришло в ответ, на вызов метода
		public function reviewData(data:Object)
		{
			//Смотрим, есть ли ошибка
			//Конструкция проверки if(data.response) была изменена, т.к в случае, если data.response была 0, If выбирал не то, что нужно. Это происходило, например, при работе с методом groups.isMember
			if(data.response != undefined){ //Объект response присутсвует, значит, запрос выполнился, и ответ есть. (Ошибки нет)
				//Если функция была задана, то вызываем фукнцию, callBack вызова метода, с результатом
				if(_vkMethodSendParams[data.callId].onSuccessFunction != null) _vkMethodSendParams[data.callId].onSuccessFunction(data.response);
			} else {//Если объекта ответа отсутствует, то вероятно, есть блок ошибки, но это не проверяется. (Ошибка есть)
				//Если функция была задана, то вызываем функцию, callBack-ошибкой, с причиной ошибки
				if(_vkMethodSendParams[data.callId].onErrorFunction != null) _vkMethodSendParams[data.callId].onErrorFunction(data.error);
			}
			
			//Удаляем информацию о вызове, которая хранит в callBack'и функции
			delete _vkMethodSendParams[data.callId];
		}

	}

}

				