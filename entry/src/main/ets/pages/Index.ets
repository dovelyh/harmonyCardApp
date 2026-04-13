/**
 * Index.ets — 元服务主界面
 *
 * ============================================================
 * 【核心概念：UIAbility 与页面的关系】
 * ============================================================
 * HarmonyOS 应用启动流程：
 *   系统 → UIAbility（EntryAbility）→ windowStage.loadContent('pages/Index')
 *                                          ↓
 *                                    加载本页面（Index.ets）
 *
 * @Entry 装饰器：标记本组件为该路由路径的入口页面。
 * 一个 UIAbility 只有一个窗口，窗口内可以通过 Navigation/Router 切换多个页面。
 * 本项目是单页应用，Index 就是唯一的页面。
 *
 * ============================================================
 * 【与卡片的数据共享方案】
 * ============================================================
 * 问题：主界面（UIAbility）和服务卡片（FormExtensionAbility）运行在不同进程，
 * 各自的 context.filesDir 路径也不同，直接用 context 读写 preferences 会是两份独立数据。
 *
 * 解决：使用 getApplicationContext() 获取应用级 context。
 * 应用级 context 的 filesDir 是所有 Ability 共享的同一路径，
 * 因此两侧用同一 name 读写的 preferences 指向同一个文件，数据天然共享。
 */

import { getMockWeather, getConditionEmoji, getGradientStart, getGradientEnd, HourlyItem, DailyItem } from '../common/WeatherData';
import { preferences } from '@kit.ArkData';
import { formBindingData, formProvider } from '@kit.FormKit';

/** 与 EntryFormAbility.ets 保持一致的 preferences key 常量 */
const PREF_NAME = 'woodenFish';
const MERIT_KEY = 'meritCount';
const FORM_IDS_KEY = 'formIds';   // 已注册卡片 formId 列表

/**
 * MeritData — 推送给卡片的增量更新数据
 *
 * 【ArkTS 约束说明】
 * formBindingData.createFormBindingData 接受一个对象参数。
 * ArkTS 严格模式要求对象字面量必须有明确类型，所以必须声明 class，
 * 不能直接传 { meritCount: n }。
 * 类声明在 struct 外部（模块作用域），struct 内部直接 new 使用。
 */
class MeritData {
  meritCount: number = 0;
}

/**
 * @Entry — 声明本 struct 为页面入口
 * @Component — 声明为 ArkUI 组件，拥有 build()/onPageShow() 等生命周期
 */
@Entry
@Component
struct Index {
  // private 字段：天气数据在组件创建时初始化一次，不参与响应式更新。
  // 如果需要天气数据也能动态刷新，应改为 @State。
  private weather = getMockWeather();
  private now = this.weather.now;
  private hourly: HourlyItem[] = this.weather.hourly;
  private daily: DailyItem[] = this.weather.daily;

  /**
   * @State — ArkUI 的响应式状态装饰器
   *
   * @State 变量变化时，ArkUI 框架会自动触发依赖该变量的 UI 片段重渲染。
   * 这是 ArkUI 单向数据流的核心：状态驱动视图（类似 React 的 useState）。
   *
   * 这里用 @State 而不是 private：
   * meritCount 会在 onPageShow/knockFish 中被修改，
   * 修改后需要页面上显示的数字立即更新，所以必须是响应式状态。
   */
  @State meritCount: number = 0;

  /**
   * getPref — 获取共享 preferences 实例
   *
   * 每次调用都重新获取（而不是缓存到成员变量）：
   * getPreferencesSync 内部会复用已有实例（同 name 返回同一对象），
   * 所以多次调用没有性能问题，也避免了成员变量生命周期管理的麻烦。
   */
  private getPref(): preferences.Preferences {
    return preferences.getPreferencesSync(
      getContext(this).getApplicationContext(), { name: PREF_NAME }
    );
  }

  /**
   * onPageShow — 页面每次可见时触发的生命周期回调
   *
   * 触发时机（均会触发）：
   *   1. 首次加载时
   *   2. 应用从后台切换到前台时
   *   3. 从卡片点击跳转进入主界面时
   *   4. Navigation 返回本页面时
   *
   * 为什么用 onPageShow 而不是 aboutToAppear？
   *   aboutToAppear：组件挂载时触发一次，之后不再触发。
   *   onPageShow：每次页面可见都触发，能感知"从卡片回到主界面"等场景。
   *
   * 这里从 preferences 刷新 meritCount，确保用户在卡片侧敲过木鱼后，
   * 打开主界面看到的是最新计数，而不是上次打开时的旧值。
   */
  onPageShow(): void {
    try {
      this.meritCount = this.getPref().getSync(MERIT_KEY, 0) as number;
    } catch {}
  }

  /**
   * knockFish — 主界面敲木鱼
   *
   * 处理步骤：
   *   1. @State meritCount +1（立即触发 UI 重渲染，用户看到数字变化）
   *   2. 写入 preferences（持久化，App 重启后数据不丢失）
   *   3. 从 preferences 读取所有已注册的卡片 formId
   *   4. 调用 formProvider.updateForm 推送新计数到所有卡片
   *
   * 为什么先改 @State 再写 preferences？
   * 先改 @State 让 UI 立即响应，用户感受不到延迟。
   * 写 preferences 是 IO 操作，即使稍慢也不影响用户体验。
   *
   * formProvider.updateForm：
   *   - 由 @kit.FormKit 提供，元服务方可以主动推送数据给自己的卡片
   *   - 只能更新属于本应用的卡片（系统安全限制）
   *   - 返回 Promise，这里 catch 错误但不等待（fire-and-forget）
   */
  private knockFish(): void {
    this.meritCount += 1;
    try {
      const pref = this.getPref();
      pref.putSync(MERIT_KEY, this.meritCount);
      pref.flush();   // 异步刷盘，不阻塞 UI

      // 读取 formId 列表并广播更新到所有桌面卡片
      const rawIds = pref.getSync(FORM_IDS_KEY, '[]') as string;
      const ids = JSON.parse(rawIds) as string[];
      const update = new MeritData();
      update.meritCount = this.meritCount;
      const binding = formBindingData.createFormBindingData(update);
      for (const id of ids) {
        formProvider.updateForm(id, binding).catch(() => {});
      }
    } catch {}
  }

  /**
   * StatCard — 今日统计数据卡片的 @Builder
   *
   * @Builder：可复用 UI 片段，接受参数。
   * layoutWeight(1)：在父 Row 中均分宽度（4张卡各占 25%）。
   * margin({ left:4, right:4 })：卡片间距，形成视觉分隔感。
   */
  @Builder
  StatCard(icon: string, value: string, label: string) {
    Column() {
      Text(icon).fontSize(22)
      Text(value)
        .fontSize(16)
        .fontColor('#333333')
        .fontWeight(FontWeight.Medium)
        .margin({ top: 6 })
      Text(label)
        .fontSize(11)
        .fontColor('#999999')
        .margin({ top: 2 })
    }
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#FFFFFF')
    .borderRadius(12)
    .padding({ top: 14, bottom: 14 })
    .layoutWeight(1)
    .margin({ left: 4, right: 4 })
  }

  /**
   * build() — 页面 UI 结构
   *
   * 整体布局：Scroll > Column > [Hero区 / 统计行 / 24h预报 / 木鱼 / 7天预报]
   *
   * Scroll：使整个页面可滚动，内容超出屏幕高度时用户可向下滑动。
   * scrollBar(BarState.Off)：隐藏滚动条，iOS/Android 常见的全屏沉浸式风格。
   *
   * 内部 Column：垂直排列所有内容块，width('100%') 撑满父容器宽度。
   */
  build() {
    Scroll() {
      Column() {

        // --------------------------------------------------------
        // Hero 区：大温度 + 天气描述，背景色跟随天气状况变化
        // linearGradient angle=180 表示从上到下的垂直渐变
        // --------------------------------------------------------
        Column() {
          Text(this.now.city)
            .fontSize(22)
            .fontColor('rgba(255,255,255,0.9)')
            .fontWeight(FontWeight.Medium)
            .margin({ top: 60 })   // 为状态栏留出空间
          Text(`${this.now.temp}°`)
            .fontSize(88)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .lineHeight(96)        // 控制大字体的行高，防止上下截断
            .margin({ top: 4 })
          Text(`${getConditionEmoji(this.now.conditionCode)} ${this.now.condition}`)
            .fontSize(20)
            .fontColor('#FFFFFF')
          Text(`体感温度 ${this.now.feelsLike}°`)
            .fontSize(15)
            .fontColor('rgba(255,255,255,0.75)')
            .margin({ top: 4 })
          Text(`最高 ${this.now.high}° / 最低 ${this.now.low}°`)
            .fontSize(15)
            .fontColor('rgba(255,255,255,0.75)')
            .margin({ top: 2, bottom: 40 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .linearGradient({
          angle: 180,
          colors: [
            [getGradientStart(this.now.conditionCode), 0.0],
            [getGradientEnd(this.now.conditionCode), 1.0]
          ]
        })

        // --------------------------------------------------------
        // 今日统计行：湿度/风力/紫外线/空气质量，4格横排
        // --------------------------------------------------------
        Row() {
          this.StatCard('💧', `${this.now.humidity}%`, '湿度')
          this.StatCard('🌬️', `${this.now.windScale}级`, this.now.windDir)
          this.StatCard('☀️', `${this.now.uvIndex}`, '紫外线')
          this.StatCard('🍃', `${this.now.airIndex}`, `空气${this.now.airQuality}`)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 16 })

        // --------------------------------------------------------
        // 24小时预报：横向滚动列表
        // 内层 Scroll 嵌套在外层 Scroll 中，需指定 scrollable(ScrollDirection.Horizontal)
        // 使内层横向滚动，外层纵向滚动，两者方向不同不会冲突。
        // --------------------------------------------------------
        Column() {
          Text('24小时预报')
            .fontSize(14)
            .fontColor('#888888')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 12 })
          Scroll() {
            Row() {
              ForEach(this.hourly, (item: HourlyItem) => {
                Column() {
                  Text(item.hour)
                    .fontSize(12)
                    .fontColor('#666666')
                  Text(getConditionEmoji(item.conditionCode))
                    .fontSize(20)
                    .margin({ top: 6, bottom: 6 })
                  Text(`${item.temp}°`)
                    .fontSize(14)
                    .fontColor('#333333')
                    .fontWeight(FontWeight.Medium)
                }
                .alignItems(HorizontalAlign.Center)
                .padding({ left: 12, right: 12 })
              })
            }
          }
          .scrollable(ScrollDirection.Horizontal)   // 横向滚动
          .scrollBar(BarState.Off)
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .padding(16)
        .margin({ left: 16, right: 16, top: 16 })

        // --------------------------------------------------------
        // 木鱼区域：可点击，每次点击功德 +1
        //
        // Stack：层叠容器，将"木鱼"文字叠加在金色圆圈背景上。
        // onClick：绑定点击事件，触发 knockFish()。
        // 注意：这里的木鱼敲击有音效支持（在 UIAbility 进程中可调用 AVPlayer），
        // 本项目暂未接入，只做计数和卡片同步。
        // --------------------------------------------------------
        Column() {
          Stack() {
            Circle()
              .width(80)
              .height(80)
              .fill('#FFD700')
              .opacity(0.15)         // 低透明度圆形光晕
            Text('木鱼')
              .fontSize(22)
              .fontColor('#B8860B')  // 深金色文字，与光晕形成层次对比
              .fontWeight(FontWeight.Bold)
          }
          .margin({ bottom: 10 })
          // @State meritCount 变化时，这里的 Text 会自动重渲染
          Text(`${this.meritCount}`)
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor('#333333')
          Text('功德值')
            .fontSize(13)
            .fontColor('#999999')
            .margin({ top: 4 })
          Text('点击积累功德')
            .fontSize(12)
            .fontColor('#BBBBBB')
            .margin({ top: 8 })
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .padding({ top: 24, bottom: 24 })
        .margin({ left: 16, right: 16, top: 16 })
        .onClick(() => this.knockFish())

        // --------------------------------------------------------
        // 7天预报列表
        // ForEach 第三个参数（keyGenerator）省略时使用 index 作为 key。
        // 如果列表会动态增删，建议提供唯一 key 以优化 diff 算法性能。
        // 这里数据固定为7条，省略无影响。
        //
        // Divider：仅在非最后一行后面插入分隔线（index < length-1），
        // 避免最后一行底部多出一条线。
        // --------------------------------------------------------
        Column() {
          Text('7天预报')
            .fontSize(14)
            .fontColor('#888888')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 4 })
          ForEach(this.daily, (item: DailyItem, index: number) => {
            Column() {
              Row() {
                Text(item.date)
                  .fontSize(15)
                  .fontColor('#333333')
                  .width(48)
                Text(getConditionEmoji(item.conditionCode))
                  .fontSize(20)
                  .margin({ left: 12 })
                Text(item.condition)
                  .fontSize(14)
                  .fontColor('#666666')
                  .margin({ left: 8 })
                  .layoutWeight(1)   // 撑满中间剩余宽度，使高低温靠右对齐
                Text(`${item.high}°`)
                  .fontSize(15)
                  .fontColor('#333333')
                  .fontWeight(FontWeight.Medium)
                Text(` / ${item.low}°`)
                  .fontSize(14)
                  .fontColor('#999999')
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              // 条件渲染：非最后一行才显示分隔线
              if (index < this.daily.length - 1) {
                Divider().strokeWidth(0.5).color('#F0F0F0')
              }
            }
          })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')
        .borderRadius(16)
        .padding({ left: 16, right: 16, top: 16, bottom: 4 })
        .margin({ left: 16, right: 16, top: 16, bottom: 32 })  // bottom: 32 防止被底部导航栏遮挡

      }
    }
    .height('100%')
    .width('100%')
    .backgroundColor('#F5F7FA')   // 浅灰色页面背景，内容卡片白色，形成层次感
    .scrollBar(BarState.Off)
  }
}
