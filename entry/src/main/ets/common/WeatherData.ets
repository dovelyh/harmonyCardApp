/**
 * WeatherData.ets — 全局唯一数据层
 *
 * 设计原则：所有数据定义和 Mock 函数集中在这一个文件，
 * FormAbility、服务卡片、主界面三者都从这里 import，避免重复定义。
 *
 * ArkTS 与 TypeScript 的关键区别：
 * ArkTS 是华为基于 TypeScript 定制的强类型语言，运行在方舟引擎（ArkCompiler）上。
 * 它在 TS 之上增加了静态类型检查、装饰器限制、禁止 any 等约束，以提升运行时性能和安全性。
 * 因此许多 TS 写法在 ArkTS 中不合法，例如：
 *   - 不能用 interface 字面量直接赋值（必须用 class 或 interface 显式声明类型）
 *   - 不能用 any 类型
 *   - 对象字面量必须有已知类型
 */

/**
 * WeatherNow — 当前天气数据结构
 * 使用 interface 而非 class：
 *   - interface 是纯类型描述，不生成运行时代码，编译后会被擦除
 *   - class 会生成运行时对象，适合需要实例化、方法调用的场景
 *   - 这里只做数据传输，用 interface 即可
 */
export interface WeatherNow {
  city: string;
  temp: number;
  condition: string;
  conditionCode: number;   // 天气状况码，100=晴，101-103=多云，104=阴，300+=雨，400+=雪
  high: number;
  low: number;
  humidity: number;
  windDir: string;
  windScale: number;
  airQuality: string;
  airIndex: number;        // AQI 空气质量指数
  uvIndex: number;
  feelsLike: number;
}

/** 逐小时预报数据项 */
export interface HourlyItem {
  hour: string;
  temp: number;
  conditionCode: number;
}

/** 单天预报数据项 */
export interface DailyItem {
  date: string;
  high: number;
  low: number;
  conditionCode: number;
  condition: string;
}

/**
 * WeatherBundle — 完整天气数据包
 * 将三层数据聚合成一个对象，方便 getMockWeather() 一次性返回所有数据。
 */
export interface WeatherBundle {
  now: WeatherNow;
  hourly: HourlyItem[];
  daily: DailyItem[];
}

/**
 * getConditionEmoji — 天气状况码 → emoji 映射
 *
 * 天气状况码是和风天气等主流气象 API 的通用编码体系：
 *   100       = 晴天
 *   101-103   = 多云（晴间多云/多云/阴间多云）
 *   104       = 阴
 *   300-399   = 雨（小雨/中雨/大雨等）
 *   400-499   = 雪
 * 这里用 emoji 代替图片资源，避免引入外部素材依赖。
 */
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

/**
 * getGradientStart / getGradientEnd — 天气状况 → 渐变色
 *
 * 卡片和主界面的背景色根据天气动态变化，增强"天气感知"视觉效果。
 * 这两个函数返回渐变的起始色和结束色，由调用方传给 ArkUI 的 .linearGradient() 修饰符。
 *
 * 为什么用两个函数而不是返回数组？
 * ArkTS 严格模式下数组字面量类型推断有时不稳定，拆成两个函数更安全直接。
 */
export function getGradientStart(code: number): string {
  if (code === 100) {
    return '#1A6DB5';        // 晴天：深蓝
  }
  if (code >= 101 && code <= 104) {
    return '#445566';        // 多云/阴：蓝灰
  }
  if (code >= 300 && code < 400) {
    return '#1E3A5F';        // 雨天：深海蓝
  }
  return '#1A6DB5';
}

export function getGradientEnd(code: number): string {
  if (code === 100) {
    return '#81CCFF';        // 晴天：浅天蓝
  }
  if (code >= 101 && code <= 104) {
    return '#889AAB';        // 多云：银灰
  }
  if (code >= 300 && code < 400) {
    return '#3D6B9E';        // 雨天：中蓝
  }
  return '#81CCFF';
}

/**
 * getMockWeather — 返回完整的模拟天气数据
 *
 * 为什么用函数而不是导出常量？
 * 函数每次调用返回新对象，防止调用方意外修改共享引用。
 * 若未来接入真实 API，只需改这一个函数的实现，所有调用方无需改动。
 *
 * conditionCode 遵循和风天气编码标准：
 *   100 = 晴，101 = 晴间多云，305 = 小雨，307 = 中雨
 */
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
