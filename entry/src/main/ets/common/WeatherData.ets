export interface WeatherNow {
  city: string;
  temp: number;
  condition: string;
  conditionCode: number;
  high: number;
  low: number;
  humidity: number;
  windDir: string;
  windScale: number;
  airQuality: string;
  airIndex: number;
  uvIndex: number;
  feelsLike: number;
}

export interface HourlyItem {
  hour: string;
  temp: number;
  conditionCode: number;
}

export interface DailyItem {
  date: string;
  high: number;
  low: number;
  conditionCode: number;
  condition: string;
}

export interface WeatherBundle {
  now: WeatherNow;
  hourly: HourlyItem[];
  daily: DailyItem[];
}

export function getConditionEmoji(code: number): string {
  if (code === 100) {
    return '☀️';
  }
  if (code >= 101 && code <= 103) {
    return '⛅';
  }
  if (code === 104) {
    return '☁️';
  }
  if (code >= 300 && code < 400) {
    return '🌧️';
  }
  if (code >= 400 && code < 500) {
    return '❄️';
  }
  return '🌤️';
}

export function getGradientStart(code: number): string {
  if (code === 100) {
    return '#1A6DB5';
  }
  if (code >= 101 && code <= 104) {
    return '#445566';
  }
  if (code >= 300 && code < 400) {
    return '#1E3A5F';
  }
  return '#1A6DB5';
}

export function getGradientEnd(code: number): string {
  if (code === 100) {
    return '#81CCFF';
  }
  if (code >= 101 && code <= 104) {
    return '#889AAB';
  }
  if (code >= 300 && code < 400) {
    return '#3D6B9E';
  }
  return '#81CCFF';
}

export function getMockWeather(): WeatherBundle {
  return {
    now: {
      city: '合肥',
      temp: 26,
      condition: '晴',
      conditionCode: 100,
      high: 29,
      low: 18,
      humidity: 45,
      windDir: '东南风',
      windScale: 3,
      airQuality: '优',
      airIndex: 42,
      uvIndex: 5,
      feelsLike: 28
    },
    hourly: [
      { hour: '现在', temp: 26, conditionCode: 100 },
      { hour: '14:00', temp: 27, conditionCode: 100 },
      { hour: '15:00', temp: 28, conditionCode: 100 },
      { hour: '16:00', temp: 28, conditionCode: 101 },
      { hour: '17:00', temp: 27, conditionCode: 101 },
      { hour: '18:00', temp: 26, conditionCode: 101 },
      { hour: '19:00', temp: 25, conditionCode: 104 },
      { hour: '20:00', temp: 24, conditionCode: 104 },
      { hour: '21:00', temp: 23, conditionCode: 104 },
      { hour: '22:00', temp: 22, conditionCode: 104 },
      { hour: '23:00', temp: 21, conditionCode: 104 },
      { hour: '00:00', temp: 20, conditionCode: 104 },
      { hour: '01:00', temp: 19, conditionCode: 104 },
      { hour: '02:00', temp: 19, conditionCode: 104 },
      { hour: '03:00', temp: 18, conditionCode: 104 },
      { hour: '04:00', temp: 18, conditionCode: 104 },
      { hour: '05:00', temp: 18, conditionCode: 104 },
      { hour: '06:00', temp: 19, conditionCode: 104 },
      { hour: '07:00', temp: 20, conditionCode: 101 },
      { hour: '08:00', temp: 21, conditionCode: 101 },
      { hour: '09:00', temp: 23, conditionCode: 100 },
      { hour: '10:00', temp: 24, conditionCode: 100 },
      { hour: '11:00', temp: 25, conditionCode: 100 },
      { hour: '12:00', temp: 26, conditionCode: 100 }
    ],
    daily: [
      { date: '今天', high: 29, low: 18, conditionCode: 100, condition: '晴' },
      { date: '明天', high: 27, low: 17, conditionCode: 101, condition: '多云' },
      { date: '周三', high: 24, low: 16, conditionCode: 305, condition: '小雨' },
      { date: '周四', high: 22, low: 15, conditionCode: 307, condition: '中雨' },
      { date: '周五', high: 25, low: 16, conditionCode: 101, condition: '多云' },
      { date: '周六', high: 28, low: 17, conditionCode: 100, condition: '晴' },
      { date: '周日', high: 30, low: 19, conditionCode: 100, condition: '晴' }
    ]
  };
}
