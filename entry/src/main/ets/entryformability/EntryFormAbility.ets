import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { getMockWeather, getConditionEmoji, getGradientStart, getGradientEnd } from '../common/WeatherData';

class WeatherFormData {
  dimension: number = 2;
  city: string = '';
  temp: number = 0;
  condition: string = '';
  conditionEmoji: string = '';
  gradientStart: string = '';
  gradientEnd: string = '';
  high: number = 0;
  low: number = 0;
  humidity: number = 0;
  windDir: string = '';
  windScale: number = 0;
  airQuality: string = '';
  airIndex: number = 0;
  uvIndex: number = 0;
  feelsLike: number = 0;
  hourlyJson: string = '[]';
  dailyJson: string = '[]';
}

export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const dimension = (want.parameters?.[formInfo.FormParam.DIMENSION_KEY] as number) ?? 2;
    const weather = getMockWeather();
    const now = weather.now;

    const data = new WeatherFormData();
    data.dimension = dimension;
    data.city = now.city;
    data.temp = now.temp;
    data.condition = now.condition;
    data.conditionEmoji = getConditionEmoji(now.conditionCode);
    data.gradientStart = getGradientStart(now.conditionCode);
    data.gradientEnd = getGradientEnd(now.conditionCode);
    data.high = now.high;
    data.low = now.low;
    data.humidity = now.humidity;
    data.windDir = now.windDir;
    data.windScale = now.windScale;
    data.airQuality = now.airQuality;
    data.airIndex = now.airIndex;
    data.uvIndex = now.uvIndex;
    data.feelsLike = now.feelsLike;
    data.hourlyJson = JSON.stringify(weather.hourly.slice(0, 6));
    data.dailyJson = JSON.stringify(weather.daily);

    return formBindingData.createFormBindingData(data);
  }

  onCastToNormalForm(formId: string): void {}

  onUpdateForm(formId: string): void {}

  onFormEvent(formId: string, message: string): void {}

  onRemoveForm(formId: string): void {}

  onAcquireFormState(want: Want) {
    return formInfo.FormState.READY;
  }
}
