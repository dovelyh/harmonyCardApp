/**
 * EntryFormAbility.ets — 服务卡片数据提供方
 *
 * ============================================================
 * 【核心概念：服务卡片的两个角色分工】
 * ============================================================
 * HarmonyOS 服务卡片由两个独立部分组成：
 *
 *   1. FormExtensionAbility（本文件）—— 运行在元服务进程中
 *      负责：提供数据、响应卡片事件、管理卡片生命周期
 *      不渲染 UI，只处理数据和逻辑
 *
 *   2. WidgetCard.ets —— 运行在桌面宿主（Launcher）进程中
 *      负责：渲染卡片 UI
 *      严格沙箱限制：无法直接调用大多数系统 API（如音频、网络等）
 *
 * 两者通过 formBindingData 传递数据，通过 postCardAction → onFormEvent 传递事件。
 *
 * ============================================================
 * 【生命周期概览】
 * ============================================================
 *   onAddForm    → 用户添加卡片时触发，必须返回初始数据
 *   onUpdateForm → 卡片刷新时触发（本项目 updateEnabled=false 故不会调用）
 *   onFormEvent  → 卡片内 postCardAction message 触发
 *   onRemoveForm → 用户删除卡片时触发
 *   onAcquireFormState → 系统查询卡片状态时触发
 */

import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { getMockWeather, getConditionEmoji, getGradientStart, getGradientEnd } from '../common/WeatherData';

/**
 * preferences 存储的 key 常量
 *
 * 为什么用 preferences 而不是数据库？
 * preferences 是 HarmonyOS 提供的轻量级 KV 存储，适合存少量简单数据（如计数、设置项）。
 * 它会将数据持久化到沙箱文件系统，App 重启后数据仍在。
 *
 * 为什么定义为常量而不是硬编码字符串？
 * 多处使用同一个 key，常量化可防止拼写错误导致读写不一致。
 */
const PREF_NAME = 'woodenFish';   // preferences 文件名（同名的文件即同一个存储）
const MERIT_KEY = 'meritCount';   // 功德计数的 key
const FORM_IDS_KEY = 'formIds';   // 已注册的所有卡片 formId 列表的 key

/**
 * FormMessage — 卡片事件消息的类型定义
 *
 * 卡片通过 postCardAction message 发送事件，消息内容会序列化为 JSON 字符串。
 * 在 onFormEvent 中解析后，用 type 字段区分不同操作（本项目只有 'knock'）。
 * 使用 interface 而非 class，因为只用于类型描述，不需要实例化。
 */
interface FormMessage {
  type: string;
}

/**
 * WeatherFormData — onAddForm 返回的完整数据结构
 *
 * 【重要】为什么必须用 class 而不能用对象字面量？
 * ArkTS 严格模式（arkts-no-untyped-obj-literals 规则）要求：
 * 对象字面量 { key: value } 必须对应某个已声明的 class 或 interface。
 * 不能直接写 const obj: Record<string, Object> = { ... }。
 *
 * 解决方案：声明 class，通过 new + 逐字段赋值，再传给 createFormBindingData。
 *
 * 字段设计要点：
 * - dimension：卡片当前规格编号，WidgetCard 据此选择渲染哪个布局
 * - hourlyJson/dailyJson：数组无法直接通过 formBindingData 传递，序列化为 JSON 字符串
 * - gradientStart/End：提前在 FormAbility 侧计算好颜色，卡片侧直接用，避免卡片重复计算
 */
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
  meritCount: number = 0;
}

/**
 * MeritData — 仅更新功德计数时使用的最小数据结构
 *
 * formProvider.updateForm 支持"增量更新"：只传变更的字段，
 * 卡片其他字段保持不变。所以敲木鱼时只需传 meritCount，
 * 不必重新传全部天气数据，节省传输量。
 */
class MeritData {
  meritCount: number = 0;
}

export default class EntryFormAbility extends FormExtensionAbility {

  /**
   * getPref — 获取 preferences 实例
   *
   * 【关键】为什么必须用 getApplicationContext() 而不是 this.context？
   *
   * HarmonyOS 中不同 Ability 有各自的 context，其 filesDir（文件目录）路径也不同：
   *   FormExtensionAbility → context.filesDir = /data/.../haps/entry/form/files/
   *   UIAbility            → context.filesDir = /data/.../haps/entry/files/
   *
   * 两个路径不同，即使 preferences 文件名相同，也是两个独立的文件！
   *
   * getApplicationContext() 返回应用级 context，所有 Ability 共享同一路径：
   *   Application context → filesDir = /data/.../files/
   *
   * 因此 FormAbility 和 UIAbility 都用 getApplicationContext()，
   * 才能读写同一份 preferences 文件，实现数据共享。
   */
  private getPref(): preferences.Preferences {
    return preferences.getPreferencesSync(this.context.getApplicationContext(), { name: PREF_NAME });
  }

  /** 读取当前功德数，读失败时返回 0（防止崩溃） */
  private getMeritCount(): number {
    try {
      return this.getPref().getSync(MERIT_KEY, 0) as number;
    } catch {
      return 0;
    }
  }

  /**
   * 保存功德数
   * putSync 写入内存缓存，flush 异步持久化到磁盘。
   * 这里不 await flush，因为 FormExtensionAbility 生命周期很短（约5秒），
   * flush 是异步但很快，不等待也没问题。
   */
  private saveMeritCount(count: number): void {
    try {
      const pref = this.getPref();
      pref.putSync(MERIT_KEY, count);
      pref.flush();
    } catch {}
  }

  /**
   * 读取已注册的全部卡片 formId 列表
   *
   * 为什么要维护 formId 列表？
   * 用户可以在桌面添加多张同一元服务的卡片（不同尺寸）。
   * 敲其中一张卡片的木鱼时，需要同步更新所有卡片的计数显示。
   * formProvider.updateForm(formId, data) 只能更新单张卡片，
   * 所以要遍历所有 formId，逐一更新。
   *
   * 存储格式：JSON 字符串，如 '["123", "456", "789"]'
   * preferences 只支持基本类型（string/number/boolean），
   * 所以用 JSON.stringify/parse 把数组序列化存储。
   */
  private getFormIds(): string[] {
    try {
      const raw = this.getPref().getSync(FORM_IDS_KEY, '[]') as string;
      return JSON.parse(raw) as string[];
    } catch {
      return [];
    }
  }

  /** 保存 formId 列表 */
  private saveFormIds(ids: string[]): void {
    try {
      const pref = this.getPref();
      pref.putSync(FORM_IDS_KEY, JSON.stringify(ids));
      pref.flush();
    } catch {}
  }

  /**
   * onAddForm — 用户将卡片添加到桌面时触发
   *
   * 参数 want 携带卡片相关参数，关键参数：
   *   IDENTITY_KEY → 本张卡片的唯一 ID（formId），系统自动分配
   *   DIMENSION_KEY → 用户选择的卡片规格（数字编码）：
   *     1 = 1×2  |  2 = 2×2  |  4 = 2×4  |  5 = 4×4  |  6 = 6×4
   *
   * 必须返回 FormBindingData，其中的字段值会注入卡片的 LocalStorage，
   * 卡片通过 @LocalStorageProp 读取这些值渲染 UI。
   *
   * 注意：want.parameters 读取要先判空，直接用 ?. 链式取值会因类型问题
   * 导致 formId 取不到（官方推荐 if (want.parameters) 的写法）。
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    const dimension = (want.parameters?.[formInfo.FormParam.DIMENSION_KEY] as number) ?? 2;

    // 将本张卡片的 formId 注册到列表，用于后续广播更新
    if (want.parameters) {
      const formId = want.parameters[formInfo.FormParam.IDENTITY_KEY] as string;
      if (formId) {
        const ids = this.getFormIds();
        if (!ids.includes(formId)) {
          ids.push(formId);
          this.saveFormIds(ids);
        }
      }
    }

    const weather = getMockWeather();
    const now = weather.now;

    // 逐字段赋值（不能用对象字面量，ArkTS 限制）
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
    // 数组必须序列化为字符串，LocalStorage 只支持基本类型
    data.hourlyJson = JSON.stringify(weather.hourly.slice(0, 6));
    data.dailyJson = JSON.stringify(weather.daily);
    // 读取当前功德数，保证新卡片和已有卡片显示一致
    data.meritCount = this.getMeritCount();

    return formBindingData.createFormBindingData(data);
  }

  /** 临时卡片转为正式卡片时触发（本项目无需额外处理） */
  onCastToNormalForm(formId: string): void {}

  /**
   * onUpdateForm — 卡片定时刷新时触发
   * 本项目 form_config.json 中 updateEnabled=false，此方法不会被系统调用。
   * 保留空实现是因为 FormExtensionAbility 接口要求实现该方法。
   */
  onUpdateForm(formId: string): void {}

  /**
   * onFormEvent — 卡片发送 message 事件时触发
   *
   * 触发路径：
   *   WidgetCard.doKnock() → postCardAction({ action: 'message', params: { type: 'knock' } })
   *   → 系统调用 EntryFormAbility.onFormEvent(formId, message)
   *   → message 是 params 的 JSON 字符串，即 '{"type":"knock"}'
   *
   * 处理逻辑：
   *   1. 解析 message 判断事件类型
   *   2. 功德数 +1，写入 preferences
   *   3. 遍历所有已注册 formId，调用 formProvider.updateForm 推送新计数
   *
   * 【为什么要在这里也做 formId 注册兜底？】
   * onAddForm 中读取 IDENTITY_KEY 有时因 want.parameters 结构问题取不到值，
   * 导致该 formId 未被注册。但 onFormEvent 的 formId 参数是系统直接传入的，
   * 100% 可靠。所以在这里再次检查并补录，确保不遗漏。
   */
  onFormEvent(formId: string, message: string): void {
    const msg = JSON.parse(message) as FormMessage;
    if (msg.type !== 'knock') {
      return;
    }

    const newCount = this.getMeritCount() + 1;
    this.saveMeritCount(newCount);

    // 构造只含 meritCount 的增量更新数据（其他字段卡片侧保持不变）
    const update = new MeritData();
    update.meritCount = newCount;
    const bindingData = formBindingData.createFormBindingData(update);

    // 兜底：确保本次事件的 formId 在列表中
    const ids = this.getFormIds();
    if (!ids.includes(formId)) {
      ids.push(formId);
      this.saveFormIds(ids);
    }

    // 广播更新所有已注册的卡片
    // formProvider.updateForm 返回 Promise，只 catch 错误不等待，
    // 避免一张卡片失败（如已被删除）阻塞其他卡片的更新。
    for (const id of ids) {
      formProvider.updateForm(id, bindingData)
        .catch((err: BusinessError) => {});
    }
  }

  /**
   * onRemoveForm — 用户删除卡片时触发
   * 从 formId 列表中移除该卡片 ID，保持列表干净，
   * 防止下次广播时对已删除的卡片发起无效的 updateForm 调用。
   */
  onRemoveForm(formId: string): void {
    const ids = this.getFormIds().filter((id: string) => id !== formId);
    this.saveFormIds(ids);
  }

  /**
   * onAcquireFormState — 系统查询卡片状态时触发
   * 返回 READY 表示卡片已就绪，可以正常展示。
   * 其他状态值：DEFAULT（默认）、ACTIVE（活跃）。
   */
  onAcquireFormState(want: Want) {
    return formInfo.FormState.READY;
  }
}
